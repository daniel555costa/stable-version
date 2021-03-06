create view VER_PAYMENT as
SELECT
      PAY.PAY_ID AS "ID",
      PAY.PAY_COD AS "CODIGO",
      AC.COUNT_NIB AS "CONTA BANCO",
      PACK_LIB.MONEY(PAY.PAY_VALUETOTAL) AS "VALOR",
      (CASE 
         WHEN PAY.PAY_OBJ_FORMAPAYMENT = 2 
            AND PAY.PAY_DOCMENTPAYMENT IS NOT NULL
            AND LENGTH(PAY.PAY_DOCMENTPAYMENT) >= 10 THEN 
            OB.OBJT_DESC || ' - '||SUBSTR(PAY.PAY_DOCMENTPAYMENT, LENGTH(PAY.PAY_DOCMENTPAYMENT) -10, LENGTH(PAY.PAY_DOCMENTPAYMENT))
         WHEN OB.OBJT_ID IS NOT NULL AND PAY.PAY_DOCMENTPAYMENT IS NOT NULL THEN OB.OBJT_DESC || ' - '||PAY.PAY_DOCMENTPAYMENT
         WHEN OB.OBJT_ID IS NOT NULL THEN OB.OBJT_DESC
         WHEN PAY.PAY_DOCMENTPAYMENT IS NOT NULL THEN PAY.PAY_DOCMENTPAYMENT
         ELSE 'Nenhuma forma de pagamento'
       END) AS "PAGAMENTO",
       MP.MPAY_DESC AS "MODO PAGAMENTO",
       TO_CHAR(PAY.PAY_DTREG, 'DD-MM-YYYY') AS "REGISTRO",
       FU.FUNC_CODSEGURADORA AS "USER",
       CASE PAY.PAY_STATE
          WHEN -1 THEN 'Anulado'
          ELSE 'Feito'
       END AS "ESTADO",
      PAY.PAY_STATE AS "COD STATE"
   FROM T_PAYMENT PAY
      INNER JOIN T_FUNCIONARIO FU ON PAY.PAY_USER_ID = FU.FUNC_ID
      INNER JOIN T_ACCOUNT AC ON PAY.PAY_ACCOUNT_ID = AC.COUNT_ID
      INNER JOIN T_OBJECTYPE OB ON PAY.PAY_OBJ_FORMAPAYMENT = OB.OBJT_ID
      INNER JOIN T_MODPAYMENT MP ON PAY.PAY_MPAY_ID = MP.MPAY_ID
  ORDER BY PAY.PAY_STATE DESC, PAY.PAY_DTREG DESC
