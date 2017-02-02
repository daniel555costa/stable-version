create or REPLACE FUNCTION  func_reg_operation_account(
   idUser NUMBER,
   idAccount NUMBER,
   idOperationValue CHARACTER VARYING(100),
   idTypeMoviment NUMBER,
   affectDefinitionCod CHARACTER VARYING
) RETURN CHARACTER VARYING
  IS

  BEGIN
    UPDATE T_OPERATION
      SET OPR_STATE = 0
      WHERE OPR_ACCOUNT_ID = idAccount
        OR (
            OPR_OPRVAL_COD = idOperationValue
            AND OPR_OPRDEF_COD = affectDefinitionCod
            );

    
    INSERT INTO T_OPERATION(
      OPR_ID,
      OPR_OPRDEF_COD,
      OPR_OPRVAL_COD,
      OPR_TMOV_ID,
      OPR_USER_ID,
      OPR_ACCOUNT_ID
    ) VALUES (
      SEQ_OPERATIONACCOUNT.nextval,
      affectDefinitionCod,
      idOperationValue,
      idTypeMoviment,
      idUser,
      idAccount
    );
    RETURN 'true;success';
  END;