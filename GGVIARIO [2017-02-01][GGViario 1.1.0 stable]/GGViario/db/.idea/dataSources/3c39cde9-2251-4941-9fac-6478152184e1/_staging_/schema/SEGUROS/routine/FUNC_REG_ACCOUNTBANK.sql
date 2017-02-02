create or REPLACE  FUNCTION           "FUNC_REG_ACCOUNTBANK" (
   idUser NUMBER,
   idBank NUMBER,
   idMoeda NUMBER,
   idTypeAccount NUMBER,
   numberAccount NUMBER
)RETURN CHARACTER VARYING
IS
  tt NUMBER;
BEGIN
  SELECT COUNT(*) INTO tt
    FROM T_ACCOUNTBANK AB
    WHERE AB.ACCOUNTBANK_NUMBER = numberAccount;

  IF tt > 0 THEN
    RETURN 'false;'||FUNC_ERROR('accoutbank-number-exit');
  END IF;
  
  INSERT INTO T_ACCOUNTBANK(
    ACCOUNTBANK_BANK_ID,
    ACCOUNTBANK_OBJ_TYPEACCOUT,
    ACCOUNTBANK_MOE_ID,
    ACCOUNTBANK_USER_ID, 
    ACCOUNTBANK_NUMBER
  ) VALUES (
    idBank,
    idTypeAccount,
    idMoeda,
    idUser,
    numberAccount
  )RETURNING ACCOUNTBANK_ID INTO tt;
  
  RETURN 'true;'||tt;
END;