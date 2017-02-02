create or REPLACE FUNCTION FUNC_REG_ACCOUNT (
  idUser NUMBER,
  accountNumber NUMBER,
  accountDescrision CHARACTER VARYING,
  accountSuperId NUMBER
) RETURN CHARACTER VARYING
IS
  vAccountRaiz T_ACCOUNT%ROWTYPE;
  idAccount NUMBER;
  iLevel NUMBER DEFAULT 0;
  nRaiz T_ACCOUNT.ACCOUNT_RAIZ%TYPE DEFAULT NULL;
  tt NUMBER;
BEGIN

  IF accountNumber >9 OR accountNumber < 0 THEN
    RETURN 'false;Numero da conta invalido';
  END IF;

  -- Se a conta nao possuir a conta super entao o id da conta do super sera a propria conta
  IF accountSuperId IS NULL THEN
    idAccount := seq_account.nextval;
    vAccountRaiz.account_id := idAccount;
  ELSE
     SELECT * INTO vAccountRaiz
        FROM T_ACCOUNT ac
        WHERE ac.account_id = accountSuperId;

      iLevel := vAccountRaiz.account_level + 1;
      nRaiz := vAccountRaiz.account_raiz||vAccountRaiz.account_number;
  END IF;

  IF vAccountRaiz.ACCOUNT_STATE = 1 THEN
    --RETURN 'false;Conta raiz esta movimentavel! Disdobra-la antes de criar as contas filhas';
    -- Desdobramento da conta nessecario
    RETURN 'false;GIJA001001';
  END IF;

  SELECT COUNT(*) INTO tt
     FROM T_ACCOUNT AC
     WHERE (AC.account_number = accountNumber
              AND accountSuperID IS NOT NULL
              AND AC.ACCOUNT_ACCOUNT_ID = accountSuperID
              AND AC.ACCOUNT_LEVEL = iLevel)

           OR (vAccountRaiz.account_raiz IS NULL
                 AND AC.ACCOUNT_RAIZ IS NULL
                 AND AC.ACCOUNT_YEAR = TO_CHAR(SYSDATE, 'YYYY')
                 AND AC.account_number = accountNumber
                 AND accountSuperID IS NULL)
        ;

  IF tt != 0 THEN
     RETURN 'false;Já exite uma conta na mesma raiz com o mesmo numero no mesmo nivel';
  END IF;

  INSERT INTO T_ACCOUNT (
    ACCOUNT_ID,
    ACCOUNT_ACCOUNT_ID,
    ACCOUNT_NUMBER,
    ACCOUNT_RAIZ,
    ACCOUNT_LEVEL,
    ACCOUNT_USER_ID,
    ACCOUNT_DESC
  ) VALUES (
    idAccount,
    vAccountRaiz.account_id,
    accountNumber,
    nRaiz,
    iLevel,
    idUser,
    accountDescrision
  );

  RETURN 'true;'||idAccount;
END;