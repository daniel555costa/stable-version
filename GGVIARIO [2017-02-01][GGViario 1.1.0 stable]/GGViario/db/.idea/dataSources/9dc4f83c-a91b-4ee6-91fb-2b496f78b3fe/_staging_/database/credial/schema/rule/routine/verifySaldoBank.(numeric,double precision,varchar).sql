CREATE FUNCTION rule.check_saldo_bank (id numeric, "ammountRequire" double precision, "idOfEntity" character varying DEFAULT 'B'::character varying) RETURNS credial.result
	LANGUAGE plpgsql
AS $$
  DECLARE
  -- idOfEntity indica que entidade deve o id pertencte {C - cheque | B - Banco}
    idBanco numeric;
    res credial.result;
    resRes credial.result;
    tt numeric;
  BEGIN
    res.result := false;
    resRes.result := FALSE ;

    -- carregar o veridadeiro id do banco
    if "idOfEntity" = 'B' then
      idBanco := id;
    elsif "idOfEntity" = 'C' then

      select cheq_banco_id into idBanco
        from credial.chequempresa
        WHERE  cheq_id = id;
    END IF;

    -- verificar o baco possui o saldo soficiente para cobrir a requisisa
    select count(*) into tt
      from  credial.banco bc
      where bc.banco_saldo >= "ammountRequire"
        and bc.banco_id = idBanco;

    if tt = 0 then
      resRes.result := message('SALDO INSUFICIENTE');
    else
      resRes.result := true;
      resRes.result := credial.message('EXISTE SALDO');
      res.result := true;
    END IF;
    res."RESULT" := resRes;
    return res;
  END;
$$
