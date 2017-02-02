CREATE OR REPLACE FUNCTION report.funct_rep_cheques_distribuidos ("idUser" integer, "idAgencia" integer, "dataInicio" date, "dataFim" date, filter json) RETURNS TABLE("ID" integer, "DATA" date, "DEBITO" character varying, "CREDITO" character varying, "BANCO SIGLA" character varying, "BANCO NAME" character varying, "AGENCIA" character varying)
	LANGUAGE plpgsql
AS $$
  DECLARE
    idBancoReport integer DEFAULT filter->'banco' ;
    idAgenciaReport integer DEFAULT filter->'agencia';



    i RECORD;
    sumDebito FLOAT DEFAULT  0;
    sumCredito FLOAT DEFAULT  0;
  BEGIN
    -- Gestao do banco
    -- Carregar os movimentos de um banco em um intervalo do tempo
    FOR i IN (
      SELECT
          bm.bancomov_id as id,
          bm.bancomov_dtreg as dataRegistro,
          bm.bancomov_debito as debito,
          bm.bancomov_credito as credito,
          bc.banco_sigla as bancoSigla,
          bc.banco_name as bancoName,
          ag.age_name as agenciaName
        FROM credial.bancomovimento bm
          INNER JOIN credial.banco bc on bm.bancomov_banco_id = bc.banco_id
          INNER JOIN credial.agencia ag ON bc.banco_age_id = ag.age_id
        WHERE bm.bancomov_dtreg BETWEEN "dataInicio" AND "dataFim"
          and (bc.banco_id = idBancoReport or idBancoReport IS NULL)
          and (ag.age_id = idAgenciaReport or idAgenciaReport  IS NULL)
    ) LOOP
      "ID" := i.id;
      "DATA" := i.dataRegistro;
      "DEBITO" := i.debito;
      "CREDITO" := i.credito;
      "BANCO SIGLA" := i.bancoSigla;
      "BANCO NAME" := i.bancoName;
      "AGENCIA" := i.agenciaName;

      sumCredito := sumCredito + i.credito;
      sumDebito := sumDebito + i.debito;

      RETURN  NEXT;
    END LOOP;

    "ID" := null;
    "DATA" := null;
    "DEBITO" := sumDebito;
    "CREDITO" := sumCredito;
    "BANCO SIGLA" := 'TOTAL';
    "BANCO NAME" := null;
    "AGENCIA" := null;

    RETURN NEXT;

  END;
$$
