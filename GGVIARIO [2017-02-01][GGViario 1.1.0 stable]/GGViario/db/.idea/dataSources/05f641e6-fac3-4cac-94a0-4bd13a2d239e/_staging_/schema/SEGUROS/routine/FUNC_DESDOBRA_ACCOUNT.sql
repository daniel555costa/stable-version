create or REPLACE FUNCTION         "FUNC_DESDOBRA_ACCOUNT" (
   idUser NUMBER,
   idAccountRaiz NUMBER,
   numberAccountDisdobre NUMBER,
   desiginacaoAccountDisdobre CHARACTER VARYING
)RETURN CHARACTER VARYING
IS
   vAccountRaiz T_ACCOUNT%ROWTYPE;
   vAccountNewRaiz T_ACCOUNT%ROWTYPE;
   idAccountNewRaiz NUMBER;
BEGIN
   SELECT * INTO vAccountRaiz
      FROM T_ACCOUNT AC
      WHERE AC.ACCOUNT_ID = idAccountRaiz;

   -- Quando a conta nao esteja movimentavel
   IF vAccountRaiz.ACCOUNT_STATE != 1 THEN
      RETURN 'false;Não pode desdobrar uma conta não movimentavel';
   END IF;

   -- Criar a nova conta como o super
   idAccountNewRaiz := seq_account.nextval;
   INSERT INTO T_ACCOUNT (
      ACCOUNT_ID,
      ACCOUNT_USER_ID,
      ACCOUNT_ACCOUNT_ID,
      ACCOUNT_RAIZ,
      ACCOUNT_NUMBER,
      ACCOUNT_LEVEL,
      ACCOUNT_DEBITO,
      ACCOUNT_CREDITO,
      ACCOUNT_DESC,
      ACCOUNT_YEAR,
      ACCOUNT_DTREG,
      ACCOUNT_STATE
   ) VALUES (
      idAccountNewRaiz,
      vAccountRaiz.account_user_id,
      vAccountRaiz.account_account_id,
      vAccountRaiz.account_raiz,
      vAccountRaiz.account_number,
      vAccountRaiz.account_level,
      0.0,
      0.0,
      vAccountRaiz.account_desc,
      vAccountRaiz.account_year,
      vAccountRaiz.account_dtreg,
      2 -- nova conta nao movimentavel como se foce a raiz
   );


   -- O super passara a ser a conta do desdobramento
   UPDATE T_ACCOUNT ac
      SET ac.account_user_id = idUser,
          ac.ACCOUNT_ACCOUNT_ID = idAccountNewRaiz,
          AC.ACCOUNT_RAIZ = vAccountRaiz.account_raiz||vAccountRaiz.account_number,
          AC.ACCOUNT_NUMBER = numberAccountDisdobre,
          ac.account_level = vAccountRaiz.account_level + 1,
          ac.account_debito = vAccountRaiz.account_debito,
          ac.account_credito = vAccountRaiz.account_credito,
          ac.account_desc = desiginacaoAccountDisdobre,
          ac.account_year = TO_CHAR(SYSDATE, 'YYYY'),
          ac.account_dtreg = SYSTIMESTAMP,
          ac.account_state = 1 -- Mater o estdo movimentavel
      WHERE AC.ACCOUNT_ID = idAccountRaiz
      ;

  RETURN 'true;'||idAccountNewRaiz;

END;