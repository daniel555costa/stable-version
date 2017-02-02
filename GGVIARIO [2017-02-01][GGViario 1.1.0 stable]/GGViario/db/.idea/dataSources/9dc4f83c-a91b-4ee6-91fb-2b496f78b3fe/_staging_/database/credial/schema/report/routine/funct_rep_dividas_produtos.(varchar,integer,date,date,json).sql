CREATE OR REPLACE FUNCTION report.funct_rep_dividas_produtos ("idUser" character varying, "idAgencia" integer, "dataInicio" date, "dataFim" date, filter json) RETURNS TABLE("ID" integer, "NIF" character varying, "NAME" character varying, "SURNAME" character varying, "CREDITO VALUE SOLICITADO" character varying, "CREDITO TOTAL PAGAR MONTANTE" character varying, "CREDITO VALUE PAGO" character varying)
	LANGUAGE plpgsql
AS $$
DECLARE
  idLocalidadeReport integer DEFAULT filter->>'localidade';
  idLocalTrabalhoReport integer DEFAULT filter->>'localTrabalho';
  idAgenciaReport integer DEFAULT filter->>'agencia';
  anoSubtriarReport integer DEFAULT filter->>'anoSub';
  idTipoCreditoReport integer DEFAULT filter->>'tipoCredito';




  -- criar data dos anos antigos
  vInterval CHARACTER VARYING DEFAULT anoSubtriarReport||' year ';
  vDataInicio DATE DEFAULT "dataInicio" - (vInterval::INTERVAL);
  vDataFim DATE DEFAULT "dataFim" - (vInterval::INTERVAL);

  i RECORD;
  sumCreditoSolicitado FLOAT DEFAULT 0;
  sumCreditoTotalPagar FLOAT DEFAULT 0;
  sumCreditoValuePago FLOAT DEFAULT 0;
BEGIN

  -- Verificar todas as dividas do intervalo do tempo fornecido
  -- Aplicar o somatorio no intervalo para os valores {CREDITO SOLICITADO, MONTANTE CREDITO, VALO PAGO}
  -- Quando a agentia ou o tipo do credito equals -1 then siginifica que se pretende carregar todas as informacoes
  FOR I IN (

    SELECT
      ce.credi_id as id,
      dos.dos_nif as nif,
      dos.dos_name as name,
      dos.dos_surname as surname,
      ce.credi_valuecredito as creditoValueSolicitado,
      ce.credi_totalpagar as creditoMontanteTotalPagar,
      ce.credi_valuepago as creditoValuePago
    FROM credial.credito ce
      INNER JOIN credial.dossiercliente dos ON ce.credi_dos_nif = dos.dos_nif
      INNER JOIN credial.historicocliente hc on dos.dos_nif = hc.hisdos_dos_nif
      INNER JOIN credial.taxa tx ON ce.credi_taxa_id = tx.taxa_id
    WHERE (ce.credi_dtinicio BETWEEN  "dataInicio" AND  "dataFim")
          and (hc.hisdos_obj_localtrabalho = idLocalTrabalhoReport OR idLocalTrabalhoReport IS NULL)
          and (hc.hisdos_local_id = idLocalidadeReport OR idLocalidadeReport IS NULL)
          and (ce.credi_age_id = idAgenciaReport OR idAgenciaReport IS NULL)
          and (tx.taxa_obj_tipocredito = idTipoCreditoReport or  idTipoCreditoReport is null)
          AND ce.credi_state = 1
          and hc.hisdos_state = 1

  ) LOOP

    "ID" := i.id;
    "NIF" := i.nif;
    "NAME" :=  i.name;
    "SURNAME" := i.surname;
    "CREDITO VALUE SOLICITADO" := i.creditoValueSolicitado;
    "CREDITO TOTAL PAGAR MONTANTE" := i.creditoMOntanteTotalPagar;
    "CREDITO VALUE PAGO" := i.creditoValuePago;

    sumCreditoSolicitado := sumCreditoSolicitado + i.creditoValueSolicitado;
    sumCreditoTotalPagar := sumCreditoTotalPagar + i.creditoMontanteTotalPagar;
    sumCreditoValuePago := sumCreditoValuePago + i.creditoValuePago;

    RETURN NEXT;

  END LOOP;

  -- Apresentar o somatorio do intervalo
  "ID" := NULL;
  "NIF" := 'TOTAL';
  "SURNAME" := NULL;
  "NAME" :=  'ANO';
  "CREDITO VALUE SOLICITADO" := sumCreditoSolicitado;
  "CREDITO TOTAL PAGAR MONTANTE" := sumCreditoTotalPagar;
  "CREDITO VALUE PAGO" := sumCreditoValuePago;

  RETURN NEXT;

  if anoSubtriarReport > 0 THEN

    SELECT
      sum(ce.credi_valuecredito),
      sum(ce.credi_totalpagar),
      sum(ce.credi_valuepago)
    into sumCreditoSolicitado,
      sumCreditoTotalPagar,
      sumCreditoValuePago

    FROM credial.credito ce
      INNER JOIN credial.dossiercliente dos ON ce.credi_dos_nif = dos.dos_nif
      INNER JOIN credial.historicocliente hc on dos.dos_nif = hc.hisdos_dos_nif
      INNER JOIN credial.taxa tx ON ce.credi_taxa_id = tx.taxa_id
      WHERE (ce.credi_dtinicio BETWEEN  vDataInicio AND vDataFim)
          and (hc.hisdos_obj_localtrabalho = idLocalTrabalhoReport OR idLocalTrabalhoReport IS NULL)
          and (hc.hisdos_local_id = idLocalidadeReport OR idLocalidadeReport IS NULL)
          and (ce.credi_age_id = idAgenciaReport OR idAgenciaReport IS NULL)
          and (tx.taxa_obj_tipocredito = idTipoCreditoReport or  idTipoCreditoReport is null)
          AND ce.credi_state = 1
          and hc.hisdos_state = 1
    ;

    "NAME" :=  anoSubtriarReport ||' anos passado';
    "CREDITO VALUE SOLICITADO" := sumCreditoSolicitado;
    "CREDITO TOTAL PAGAR MONTANTE" := sumCreditoTotalPagar;
    "CREDITO VALUE PAGO" := sumCreditoValuePago;

  END IF;

  RETURN NEXT;

END;
$$
