create OR REPLACE PROCEDURE PRC_REG_MOVIMENTATION_PAYMENT
(
   idUser NUMBER,
   idAccount NUMBER,
   idTypeMoviment NUMBER,
   amountValue FLOAT,
   dateMoviment DATE,
   dbCod CHARACTER VARYING,
   operationType CHARACTER VARYING,
   codVall CHARACTER VARYING
)
IS
   idAccount NUMBER := idAccontPayment;
BEGIN
   -- DEPOIS QUE FOR REGISTRAODO A MOVIEMHNTACAO NA CONTA DO PAGAMENTO 
      -- O SALDO DO CREDITO NA CONATA OU O SALDO DO DEBITO NA CONTA SERAO AUMENTADO DEPENDENDO DO TIPKI DE MOVOIMENTACAO 
      -- EFETUADA NA CONTA MOVIMENTACAO.TMOV_ID{1 - CREDITO <DEVERA AUMENTAR O SALADO DO CREDITO NA CONTA DO PAGAMNETO>
                                      ---       2 - DEBITO <DEVERA AUMENTAR O SALDO DO DEBITO NA CONTA DO PAGAMENTO> }
   INSERT INTO T_MOVIMENTACCOUNTPAY(MOVCOUNTPAY_ACCOUNT_ID,
                                    MOVCOUNTPAY_TMOV_ID,
                                    MOVCOUNTPAY_USER_ID,
                                    MOVCOUNTPAY_VALUE,
                                    MOVCOUNTPAY_DATE,
                                    MOVCOUNTPAY_DBCOD,
                                    MOVCOUNTPAY_OPR,
                                    MOVCOUNTPAY_CODVALL)
                                    VALUES(idAccount,
                                           idTypeMoviment,
                                           idUser,
                                           amountValue,
                                           dateMoviment,
                                           dbCod,
                                           operationType,
                                           codVall);
END;