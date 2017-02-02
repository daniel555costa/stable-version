CREATE or REPLACE FUNCTION funct_cheque_restore_effect () RETURNS TABLE("ID" integer, "OPR" integer, "OPERATION" character varying, "BANCO" character varying, "AGENCIA" character varying, "INICIO" character varying, "FIM" character varying, "NUM FOLHAS" integer, "NUM FOLHAS RESTANTE" integer)
	LANGUAGE plpgsql
AS $$
DECLARE
  vCheque RECORD;
  aux RECORD;
  reativeCheque RECORD;

  banco CHARACTER VARYING;
  agenciaName CHARACTER VARYING;
  iCount INTEGER DEFAULT 0;
BEGIN

  SELECT ch.*, b.*, a.* into vCheque
  from credial.chequempresa ch
    inner JOIN credial.agencia a on ch.cheq_age_id = a.age_id
    inner JOIN credial."conta" ct ON ch.cheq_conta_id = ct.conta_id
    INNER JOIN credial."banco" b on ct."conta_banco_id" = "b"."banco_id"
  where ch.cheq_state = 1
        and ch.cheq_dtreg >= (now() - INTERVAL '1' DAY)
  order by ch.cheq_dtreg desc
  LIMIT 1;


  if vCheque.cheq_id is not null
     and vCheque.cheq_distribuido = 0 then

    "ID" := vCheque.cheq_id;
    "OPR" := -1;
    "OPERATION" := 'Remover';
    "BANCO" := vCheque.banco_sigla;
    "AGENCIA" := vCheque.age_name;
    "INICIO" := vCheque.cheq_sequenceinicio;
    "FIM" := vCheque.cheq_sequencefim;
    "NUM FOLHAS" := vCheque.cheq_total;
    "NUM FOLHAS RESTANTE" := vCheque.cheq_total - vCheque.cheq_distribuido;

    RETURN NEXT;


    SELECT ch.*, b.*, a.* into aux
    from chequempresa ch
      inner JOIN agencia a on ch.cheq_age_id = a.age_id
      inner JOIN "conta" ct ON ch.cheq_conta_id = ct.conta_id
      INNER JOIN "banco" b on ct."conta_banco_id" = "b"."banco_id"
    where ch.cheq_dtreg < vCheque.cheq_dtreg
          AND ch.cheq_conta_id = vCheque.cheq_conta_id
          AND ch.cheq_age_owner = vCheque.cheq_age_owner
    order by ch.cheq_dtreg desc
    LIMIT 1;

    RAISE NOTICE '%', aux;

    vCheque := aux;
    if vCheque.cheq_id is NOT null
       and vCheque.cheq_distribuido  < vCheque.cheq_total THEN

      "ID" := vCheque.cheq_id;
      "OPR" := 1;
      "OPERATION" := 'Reativar';
      "BANCO" := vCheque.banco_sigla;
      "AGENCIA" := vCheque.age_name;
      "INICIO" := vCheque.cheq_sequenceinicio;
      "FIM" := vCheque.cheq_sequencefim;
      "NUM FOLHAS" := vCheque.cheq_total;
      "NUM FOLHAS RESTANTE" := vCheque.cheq_total - vCheque.cheq_distribuido;

      RETURN NEXT;
    END IF;

  END IF;

END;

$$
