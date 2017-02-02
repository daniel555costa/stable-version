create or REPLACE FUNCTION FUNC_REG_AMORTIZCAO
(
    PRESTACAO_ID NUMBER,
    USER_ID NUMBER,
    VALOR_amortizar FLOAT,
    DOCUMENTO_numero VARCHAR,
    tipo_pagamento NUMBER,
    conta_amortizacao NUMBER
)  RETURN VARCHAR2
    IS
       contrato T_CONTRATO%ROWTYPE;
       contaAmortizacao T_ACCOUNT%ROWTYPE;
       valorCambiadoConta DOUBLE PRECISION;
       taxa T_TAXA%ROWTYPE;
       tt NUMBER;
       
       missingAccount CHARACTER VARYING(4000); 
       money CHARACTER VARYING(1000);
       taxaVenda FLOAT;
       idTypeMoviment NUMBER;
       idPayment NUMBER;
       
       stdMoney T_MOEDA%ROWTYPE DEFAULT PACK_CONTA.getSTDMoney();
    BEGIN
    
      
      SELECT * INTO contaAmortizacao
         FROM T_ACCOUNT AC
         WHERE AC.ACCOUNT_ID = conta_amortizacao;
         
      SELECT CT.* INTO contrato
         FROM T_CONTRATO CT
            INNER JOIN T_PRESTACAO PRE ON CT.CTT_ID = PRE.PREST_CTT_ID
         WHERE PRE.PREST_ID = PRESTACAO_ID;
    
    
    -- Moeda de contrato as Moeda base
    -- Moeda da conta as Moeda To 
    -- The values is convert from base money to dentination money | values as money contrato to momey account
    
    -- Quando as moedas da conta e a moeda do contrato forem diferente então deve ser criado cambio entre a moeda do contrato em relacao a moeda da conta
    IF  contrato.CTT_MOE_ID != stdMoney.moe_id THEN
    
        -- Verificar se existe a taxa de conversao entre as moedas de contratos e as moedas de conta
        SELECT COUNT(*) INTO tt
           FROM TABLE(PACK_CONTA.GETTAXAMONEY(contrato.CTT_DTREG, contrato.CTT_MOE_ID, stdMoney.MOE_ID));
           
        IF tt = 0  THEN 
            RETURN 'false;'||FUNC_ERROR('TAXA NOT FOUND BETWEEN MONEYs');
        END IF;
        
        -- Carregar a taxa de conversao entre as moedas 
        SELECT * INTO taxa
           FROM TABLE(PACK_CONTA.GETTAXAMONEY(contrato.CTT_DTREG, contrato.CTT_MOE_ID, stdMoney.MOE_ID))
           WHERE ROWNUM <= 1;
        
        valorCambiadoConta := VALOR_amortizar * taxa.TX_VENDA;
    ELSE
       -- Para o casa da moeda do contrato ser igual a moeda da conta entao o valor a ser creditado na conta sera o valor a amortizacao
       -- WARNING CREDITO AS DEBITO AND DEBITO AS CREITO
       valorCambiadoConta := VALOR_amortizar;
    END IF;
    
/*
    -- VERIFICAR SE TODAS AS CONTA DE DESTINO EXTEJEM PREVIAMENTE CADASTRADo NO SISTEMA
    -- EM CASO DE AUSENCIA DE ALGUMAS DESSA CONTAS O SISTEMA DEVERA ANULAR O REGISTRO DE CONTRATO FEITO APRESENTADO AS CONTAS FALTOSAS
    missingAccount := PACK_VALIDATE.GETMISSINGACCOUNTOPERACTION(contrato.CTT_SEG_ID, 'PAY');
    
    IF missingAccount IS NOT NULL THEN
       RETURN 'false;'||missingAccount;
    END IF;
*/
      INSERT INTO T_AMORTIZACAO(AMORT_PREST_ID,
                                AMORT_USER_ID,
                                AMORT_VALOR,
                                AMORT_DOCUMENTO,
                                AMORT_OBJT_ID,
                                AMORT_ACCOUNT_ID,
                                AMORT_VALUEACCOUNT
                                )VALUES(PRESTACAO_ID,
                                        USER_ID,
                                        VALOR_amortizar,
                                        DOCUMENTO_numero,
                                        tipo_pagamento,
                                        conta_amortizacao,
                                        valorCambiadoConta)
                                        RETURNING AMORT_ID INTO idPayment;
                                        
      SELECT MD.MOE_SIGLA INTO money
         FROM T_MOEDA MD
         WHERE MD.MOE_ID = contrato.CTT_MOE_ID;

      -- Para os contrattos em moeda estrangeiras caregar a taxa de cambio do dia do contrato ~= SYSTIMESTAMP
      IF money != 'STD'  THEN
          SELECT * INTO taxa
             FROM TABLE(PACK_CONTA.GETTAXADAY(contrato.CTT_DTREG, contrato.CTT_MOE_ID)) TAX;
          taxaVenda := taxa.TX_VENDA;
      ELSE
         taxaVenda := 1;
      END IF;
      
      FOR OP IN(SELECT *
                   FROM VER_OPERATION_ACCOUNT OP
                   WHERE OP.GROUP_COD = 'REG.REC'
                      AND OP.AFETAVEL_KEY IN (contrato.CTT_SEG_ID||'', 'ALL'))
      LOOP
         idTypeMoviment := NULL;
         /*
            TIPO MOVIMENTO {
                    WHEN TMOV_ID = 1 THEN 'DEBITO'
                    WHEN TMOV_ID = 2 THEN 'CREDITO'
            }
         */
            
        /* IF OP.TYPEMOVIMENT = 'DEBITO' THEN idTypeMoviment := 1; -- DEBITO AS 1
         ELSIF OP."TIPO MOVIMENTO" = 'CREDITO' THEN idTypeMoviment := 2; -- CREDITO AS 2
         END IF;
        */
         idTypeMoviment := OP.TYPEMOVIMENT_ID;

        IF OP.VALUE = 'REC-VALUE' THEN
         -- Reg Movimentation Account
         PRC_REG_MOVIMENTATION_PAYMENT(USER_ID, OP.ACCOUNT_ID, idTypeMoviment, (VALOR_amortizar * taxaVenda), SYSDATE, idPayment, 'REG.PAY', OP.VALUE);
        END IF;
      END LOOP;
                                        
      RETURN 'true;'||FUNC_ERROR('OK') ;                       
                              
    END;