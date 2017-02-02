create OR REPLACE FUNCTION  func_reg_operation_account(
   idUser NUMBER,
   idAccount NUMBER,
   idOperationValue CHARACTER VARYING,
   idTypeMoviment NUMBER,
   affectDefinitionCod CHARACTER VARYING
) RETURN CHARACTER VARYING
  IS
    id_num number default SEQ_OPERATIONACCOUNT.nextval;

  BEGIN
    UPDATE T_OPERATION
      SET OPR_STATE = 0
      WHERE OPR_ACCOUNT_ID = idAccount
        AND OPR_OPRDEF_COD = affectDefinitionCod
        AND OPR_OPRVAL_COD = idOperationValue;

    
    INSERT INTO T_OPERATION(
      OPR_ID,
      OPR_OPRDEF_COD,
      OPR_OPRVAL_COD,
      OPR_TMOV_ID,
      OPR_USER_ID,
      OPR_ACCOUNT_ID
    ) VALUES (
       id_num,
      affectDefinitionCod,
      idOperationValue,
      idTypeMoviment,
      idUser,
      idAccount
    );

    RETURN 'true;success';
  END;