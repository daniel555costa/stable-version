CREATE OR REPLACE FUNCTION report.funct_rep_client_credito_contagem (
  "idUser" character varying,
  "idAgencia" integer,
  "dataInicio" date,
  "dataFim" date,
  filter json
) RETURNS TABLE(

  "NIF" character varying,
  "NAME" character varying,
  "SURNAME" character varying,
  "VALOR" character varying,
  "LOCAL TRABALHO" character varying

)
	LANGUAGE plpgsql
AS $$
    DECLARE
      
      idLocalTrabalhoReport integer DEFAULT filter->>'localTrabalho';
      idLocalidadeReport integer DEFAULT filter->>'localidade';
      idAgenciaReport integer DEFAULT filter->>'agencia';
      idTipoCreditoReport integer DEFAULT filter->>'tipoCredito';
      
        

      totalCredito INTEGER DEFAULT 0;
      i RECORD;

      -- funct_historicocliente(dos_nif)


    BEGIN

      FOR I IN (

        SELECT
            dos.dos_nif as nif,
            dos.dos_name as name,
            dos.dos_surname as surname,
            lt.obj_desc as localTrabalho,
            count(*) as totalCredito

          from credial.dossiercliente dos
            INNER JOIN credial.historicocliente his ON dos.dos_nif = his.hisdos_dos_nif
            INNER JOIN credial.objecto lt on his.hisdos_obj_localtrabalho = lt.obj_id
            INNER JOIN credial.credito ce ON dos.dos_nif = ce.credi_dos_nif
            INNER JOIN credial.taxa tx ON ce.credi_taxa_id = tx.taxa_id
          WHERE ce.credi_dtinicio BETWEEN "dataInicio" AND "dataFim"
            and (ce.credi_age_id = idAgenciaReport or idAgenciaReport IS NULl)
            and (tx.taxa_obj_tipocredito = idTipoCreditoReport or idTipoCreditoReport IS NULL)
            and (his.hisdos_obj_localtrabalho = idLocalTrabalhoReport or idLocalTrabalhoReport IS NULL)
            and (his.hisdos_local_id = idLocalidadeReport or idLocalidadeReport IS NULL)
          GROUP BY nif, name, surname, localTrabalho
          ORDER BY totalCredito DESC

      ) LOOP

        IF i.totalCredito IS NOT NULL THEN

          "NIF" := i.nif;
          "NAME" := i.name;
          "SURNAME" := i.surname;
          "VALOR" := i.totalCredito;
          "LOCAL TRABALHO" := i.localTrabalho;

          totalCredito := totalCredito + i.totalCredito;
          RETURN NEXT;

        END IF;
      END  LOOP;

      "NIF" := 'TOTAL';
      "NAME" := NULL;
      "SURNAME" := NULL;
      "VALOR" := totalCredito;
      "LOCAL TRABALHO" := null;

      RETURN  NEXT ;
    END;
$$
