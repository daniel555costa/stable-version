CREATE or REPLACE FUNCTION report.funct_rep_cheques_saldo_diario ("idUser" integer, "idAgencia" integer, filter json) RETURNS TABLE("ID" integer, "HORA" time without time zone, "DEBITO" character varying, "CREDITO" character varying, "DESIGINACAO OPERACAO" character varying)
	LANGUAGE plpgsql
AS $$
  DECLARE
    -- enter param
    idBancoReport integer DEFAULT filter->>'banco';
    dataDiaReport  date DEFAULT  filter->>'dataDia';
    idAgenciaReport integer DEFAULT  filter->>'agencia';
    
    
    
    -- Gestao do Banco
    -- Visualizar os hitoricos dos movimento feitos num banco
    -- Em um dado intervalo de tempo em um dia

    -- Nao necessario(Quando data nula todas as movimentações serao caregada)
    sumDebito FLOAT DEFAULT 0;
    sumCredito FLOAT DEFAULT 0;
    i RECORD;
  BEGIN

    FOR I IN (

      select
          bm.bancomov_id as id,
          bm.bancomov_dtreg::TIME as hora,
          bm.bancomov_debito as debito,
          bm.bancomov_credito as credito,
          bm.bancomov_libele as operaction
        from credial.bancomovimento bm
          where (bm.bancomov_dtreg::date == dataDiaReport)
            and (bm.bancomov_banco_id = idBancoReport)
            and (bm.bancomov_age_id = idAgenciaReport)
        ORDER BY bm.bancomov_dtreg desc
    ) LOOP
      "ID" := i.id;
      "HORA" := i.hora;
      "DEBITO" := i.debito;
      "CREDITO" := i.credito;
      "DESIGINACAO OPERACAO" := i.operaction;

      sumCredito := sumCredito + i.credito;
      sumDebito := sumDebito + i.debito;

      RETURN NEXT;

    END LOOP;

    "ID" := NULL;
    "HORA" :=  NULL;
    "DEBITO" := sumDebito ;
    "CREDITO" := sumCredito;
    "DESIGINACAO OPERACAO" := 'TOTAL';
    
    RETURN NEXT ;
  END;
$$
