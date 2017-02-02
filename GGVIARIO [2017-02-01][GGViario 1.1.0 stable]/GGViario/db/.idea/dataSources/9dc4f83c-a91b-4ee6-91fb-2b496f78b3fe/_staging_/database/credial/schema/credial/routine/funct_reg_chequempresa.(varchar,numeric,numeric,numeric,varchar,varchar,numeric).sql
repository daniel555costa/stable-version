DROP FUNCTION funct_reg_chequempresa ("idUser" character varying, "idAgencia" numeric, "idBanco" numeric, "idAgenciaPropetariaDoCheque" numeric, "sequenciaChequeInicial" character varying, "sequenciaChequeFinal" character varying, "totalChequesEmpresa" numeric);


CREATE OR REPLACE FUNCTION funct_reg_chequempresa ("idUser" character varying, "idAgencia" numeric, idConta numeric, "idAgenciaPropetariaDoCheque" numeric, "sequenciaChequeInicial" character varying, "sequenciaChequeFinal" character varying, "totalChequesEmpresa" numeric) RETURNS result
	LANGUAGE plpgsql
AS $$
  declare
    vValidate "ValidateResult";
    res result;
    
    vChequeInicio CHARACTER VARYING;
    vChequeFim CHARACTER VARYING;
    
    vConta RECORD;
    
  begin
    
    -- o idBanco correspnde ao id-da-conta 
    res.result := FALSE;
    -- Validar os numeros das sequencia do cheque
    vValidate := rule."validateSequenciaCheque"("sequenciaChequeInicial", "sequenciaChequeFinal");
    if not vValidate."RESULT" then
      res.result := FALSE;
      res.message := vValidate."MESSAGE";
    END IF;
    
    
    
    SELECT  *  INTO vConta
      from credial.conta ct
        INNER JOIN credial.banco bc on ct.conta_banco_id = bc.banco_id
      where ct.conta_id = idConta;

    IF vConta.banco_cod IS NULL THEN
      res.result = false;
      res.message := message('no-cod-bank');
      RETURN res;
    END IF;

    vChequeInicio := vConta.banco_cod||vConta.conta_agenciacod||vConta.conta_numero||"sequenciaChequeInicial";
    vChequeFim := vConta.banco_cod||vConta.conta_agenciacod||vConta.conta_numero||"sequenciaChequeFinal";
    

    -- Desativar a titiga carteira do banco na agencia
    update chequempresa
      set cheq_state = 0
      where cheq_conta_id  = idConta
        and cheq_age_owner = "idAgenciaPropetariaDoCheque"
        and cheq_state = 1;

    insert into chequempresa(
      cheq_age_owner,
      cheq_age_id,
      cheq_conta_id,
      cheq_user_id,
      cheq_sequenceinicio,
      cheq_sequencefim,
      cheq_total
    ) values (
      "idAgenciaPropetariaDoCheque",
      "idAgencia",
      idConta,
      "idUser",
      vChequeInicio,
      vChequeFim,
      "totalChequesEmpresa"
    );

    res.result := 'true';
    res.message := 'Sucess0';
    return res;
  end;
$$
