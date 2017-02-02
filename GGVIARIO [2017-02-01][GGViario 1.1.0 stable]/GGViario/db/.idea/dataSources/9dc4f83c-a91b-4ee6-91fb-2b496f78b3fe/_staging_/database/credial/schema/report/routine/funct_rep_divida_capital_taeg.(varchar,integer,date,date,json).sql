CREATE or REPLACE FUNCTION report.funct_rep_divida_capital_taeg ("idUser" character varying, "idAgencia" integer, "dataInicio" date, "dataFim" date, filter json) RETURNS TABLE("NIF" character varying, "NAME" character varying, "SURNAME" character varying, "CREDITO STATE" character varying, "CREDITO VALUE" character varying, "CREDITO NUM DOSSCIER" character varying, "CREDITO TOTAL PAGAR MONTANTE DIVIDA" character varying, "CREDITO TAEG" character varying, "CREDITO INICIO" character varying, "CREDITO FINALIZAR" character varying)
	LANGUAGE plpgsql
AS $$
DECLARE
  anoSubtrairReport integer DEFAULT filter->>'anoSub';
  idAgenciaReport integer DEFAULT filter->>'agencia';
  idTipoCreditoReport integer DEFAULT filter->>'tipoCredito';
    
  -- criar data dos anos antigos
  vInterval CHARACTER VARYING DEFAULT anoSubtrairReport||' year ';
  vDataInicio DATE DEFAULT "dataInicio" - (vInterval::INTERVAL);
  vDataFim DATE DEFAULT "dataFim" - (vInterval::INTERVAL);

  sumValorCredito FLOAT DEFAULT 0;
  sumValorPagarMontanteDiviada FLOAT DEFAULT 0;
  sumValorTaeg FLOAT DEFAULT 0;

  I RECORD;


BEGIN

  -- Apresentar os creditos no intervalo fornecido e calcular os somatorios corresnpondentes
  -- Quando a agentia ou o tipo do credito equals -1 then siginifica que se pretende carregar todas as informacoes

  FOR I IN(
    SELECT
      dc.DOS_NIF AS nif,
      dc.dos_name AS name,
      dc.dos_surname AS surname,
      cd.credi_dtrge AS datareg,
      CASE
      WHEN cd.credi_creditostate = 1 THEN 'Por Pagar'
      ELSE 'Pago'
      END AS creditoState,

      cd.credi_valuecredito  AS valueCredito,
      cd.credi_numcredito as numCreditoDosscier,
      cd.credi_totalpagar AS totalPayMontanteDivida,
      cd.credi_taeg AS taeg,
      cd.credi_dtinicio AS inicio ,
      cd.credi_dtfinalizar AS finalizar
    FROM credial.dossiercliente dc
      INNER JOIN credial.credito cd ON dc.dos_nif = cd.credi_dos_nif
      INNER JOIN credial.taxa tx ON cd.credi_taxa_id = tx.taxa_id
    WHERE cd.credi_dtinicio BETWEEN "dataInicio" AND "dataFim"
          AND (cd.credi_age_id = idAgenciaReport OR idAgenciaReport IS NULL)
          AND (tx.taxa_obj_tipocredito = idTipoCreditoReport OR idTipoCreditoReport IS NULL)
          AND (cd.credi_creditostate = 1)
  )
  LOOP

    sumValorCredito := sumValorCredito + I.valueCredito;
    sumValorPagarMontanteDiviada := sumValorPagarMontanteDiviada + I.totalPayMontanteDivida;
    sumValorTaeg := sumValorTaeg + I.taeg;

    "NIF" := I.nif;
    "NAME" := I.name;
    "SURNAME" := I.surname;
    "CREDITO STATE" := I.creditoState;
    "CREDITO VALUE" := I.valueCredito;
    "CREDITO TOTAL PAGAR MONTANTE DIVIDA" := I.totalPayMontanteDivida;
    "CREDITO TAEG" := I.taeg;
    "CREDITO INICIO" := I.inicio;
    "CREDITO FINALIZAR" := I.finalizar;
    "CREDITO NUM DOSSCIER" := I.numCreditoDosscier;

    RETURN NEXT;

  END LOOP;

  "NIF" := 'TOTAL';
  "NAME" := 'ANO';
  "SURNAME" := NULL;
  "CREDITO STATE" := NULL;
  "CREDITO VALUE" := sumValorCredito;
  "CREDITO TOTAL PAGAR MONTANTE DIVIDA" := sumValorPagarMontanteDiviada;
  "CREDITO TAEG" := sumValorTaeg;
  "CREDITO INICIO" := NULL;
  "CREDITO FINALIZAR" := NULL;
  "CREDITO NUM DOSSCIER" := NULL;
  RETURN NEXT;

  IF anoSubtrairReport > 0 THEN

    sumValorCredito := 0;
    sumValorPagarMontanteDiviada := 0;
    sumValorTaeg := 0;

    SELECT
      sum(cd.credi_valuecredito),
      sum(cd.credi_totalpagar),
      sum(cd.credi_taeg )
    INTO sumValorCredito,
      sumValorPagarMontanteDiviada,
      sumValorTaeg
    FROM credial.dossiercliente dc
      INNER JOIN credial.credito cd ON dc.dos_nif = cd.credi_dos_nif
      INNER JOIN credial.taxa tx ON cd.credi_taxa_id = tx.taxa_id
    WHERE cd.credi_dtinicio BETWEEN vDataInicio AND vDataFim
          AND (cd.credi_age_id = idAgenciaReport OR idAgenciaReport IS NULL)
          AND (tx.taxa_obj_tipocredito = idTipoCreditoReport OR idTipoCreditoReport IS NULL)
          AND (cd.credi_creditostate = 1)
    ;

    "CREDITO VALUE" := sumValorCredito;
    "CREDITO TOTAL PAGAR MONTANTE DIVIDA" := sumValorPagarMontanteDiviada;
    "CREDITO TAEG" := sumValorTaeg;
  END IF;

  "NAME" := anoSubtrairReport ||' anos passado';
  RETURN NEXT;

END;
$$
