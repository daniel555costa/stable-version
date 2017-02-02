CREATE FUNCTION report.funct_rep_client_credito (
  iduser character varying,
  idagencia integer,
  "dataInicio" date,
  "dataFim" date,
  filter json
) RETURNS TABLE(

  "NIF" character varying,
  "NAME" character varying,
  "SURNAME" character varying,
  "VALOR" character varying,
  "QUANTIDADE CREDITO" INTEGER,
  "LOCAL TRABALHO" character varying

)
	LANGUAGE plpgsql
AS $$
    DECLARE

      idLocalTabalhoReport integer DEFAULT filter->>'localTrabalho';
      idLocalidadeReport integer DEFAULT filter ->>'localidade';
      idAgenciaReport integer DEFAULT  filter ->>'agencia';
      idTipoCreditoReport integer DEFAULT filter->>'tipoCredito';

      sumMontanteTotalCredito DOUBLE PRECISION DEFAULT 0;
      sumQuantidadeTotal INTEGER;

      i RECORD;

      -- funct_historicocliente(dos_nif)

    BEGIN

      FOR I IN (

        SELECT
            dos.dos_nif as nif,
            dos.dos_name as name,
            dos.dos_surname as surname,
            lt.obj_desc as localTrabalho,
            sum(ce.credi_valuecredito) as valorCredito,
            count(ce.credi_id) as quantidadeTotal

          from credial.dossiercliente dos
            INNER JOIN credial.historicocliente his ON dos.dos_nif = his.hisdos_dos_nif
            INNER JOIN credial.objecto lt on his.hisdos_obj_localtrabalho = lt.obj_id
            INNER JOIN credial.credito ce ON dos.dos_nif = ce.credi_dos_nif
            INNER JOIN credial.taxa tx ON ce.credi_taxa_id = tx.taxa_id
          WHERE ce.credi_dtinicio BETWEEN "dataInicio" AND "dataFim"
            and (ce.credi_age_id = idAgenciaReport or  idAgenciaReport is null)
            and (tx.taxa_obj_tipocredito = idTipoCreditoReport or  idTipoCreditoReport is null)
            and (his.hisdos_obj_localtrabalho = idLocalTabalhoReport or idLocalTabalhoReport is null)
            and (his.hisdos_local_id = idLocalidadeReport or idLocalidadeReport is null)
          GROUP BY nif, name, surname, localTrabalho
          ORDER BY valorCredito DESC

      ) LOOP

        IF i.valorCredito IS NOT NULL THEN

          "NIF" := i.nif;
          "NAME" := i.name;
          "SURNAME" := i.surname;
          "VALOR" := i.valorCredito;
          "LOCAL TRABALHO" := i.localTrabalho;
          "QUANTIDADE CREDITO" := i.quantidadeTotal;

          sumQuantidadeTotal := sumQuantidadeTotal + i.quantidadeTotal;
          sumMontanteTotalCredito := sumMontanteTotalCredito + i.valorCredito;
          RETURN NEXT;

        END IF;
      END  LOOP;

      "NIF" := 'TOTAL';
      "NAME" := NULL;
      "SURNAME" := NULL;
      "LOCAL TRABALHO" := NULL;
      "QUANTIDADE TOTAL" := sumQuantidadeTotal;
      "VALOR" := sumMontanteTotalCredito;

      RETURN  NEXT ;
    END;
$$
