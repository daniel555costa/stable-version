create trigger TG_POS_REG_PAYMENT
	after insert or update
	on T_PAYMENT
	for each row
DECLARE
   cheque T_CHEQUE%ROWTYPE;
   conta T_ACCOUNT%ROWTYPE;
   
BEGIN
  -- TIME DO REGISTRO TIME {1 - PAGAMENTO NOVO| 0 - PAGAMENTO ANTIGO}
   IF INSERTING THEN
   
       SELECT AC.* INTO conta
         FROM T_ACCOUNT AC
         WHERE AC.COUNT_ID = :NEW.PAY_ACCOUNT_ID;
   
   
       -- Se for um pagamento via cheque reitara o sequencia do seu cheque
       IF :NEW.PAY_OBJ_FORMAPAYMENT = 2 THEN
       
           SELECT * INTO cheque
              FROM (SELECT * 
                       FROM T_CHEQUE CH
                       WHERE CH.CHEQUE_ACCOUNT_ID = :NEW.PAY_ACCOUNT_ID
                          AND CH.CHEQUE_TIME = :NEW.PAY_TIME
                          -- Se o tempo do cheque for pasado pegar o cheque que estaja desativado e que estaja passado
                          AND CH.CHEQUE_STATE = CASE -- pasado pega dedativo
                                                   WHEN :NEW.PAY_TIME = 0 THEN 0
                                                   ELSE 1
                                                END-- Time{1 - cheque novo estao activio | 0 cheque passado estao desativos
                          )
              WHERE ROWNUM <= 1;
                
          -- Quando o pagamento for um pagamento passado então aumentar a quantidade do cheque nessa cratira para +1
          IF :NEW.PAY_TIME = 0 THEN 
          
             UPDATE T_CHEQUE CH
                SET CH.CHEQUE_TTCHEQUE = CH.CHEQUE_TTCHEQUE +1
                WHERE CH.CHEQUE_ID = cheque.CHEQUE_ID;
                
             cheque.CHEQUE_TTCHEQUE := cheque.CHEQUE_TTCHEQUE +1;
          END IF;
          
          -- retirar um cheque da cateira ou desabiliatar a carateira atual do cheque
          UPDATE T_CHEQUE  CH
             SET CH.CHEQUE_STATE = (CASE WHEN cheque.CHEQUE_TTDESTRIBUIDO +1 = cheque.CHEQUE_TTCHEQUE THEN 0 ELSE 1 END ),
                 CH.CHEQUE_TTDESTRIBUIDO = CH.CHEQUE_TTDESTRIBUIDO + 1
             WHERE CH.CHEQUE_ID = cheque.CHEQUE_ID;
       END IF;
       
    ELSIF UPDATING  THEN
    
       SELECT AC.* INTO conta
         FROM T_ACCOUNT AC
         WHERE AC.COUNT_ID = :OLD.PAY_ACCOUNT_ID;
         
       IF :OLD.PAY_STATE = 2 AND :NEW.PAY_STATE = 1 THEN 
          UPDATE T_ACCOUNT AC 
            SET AC.COUNT_CREDITO = AC.COUNT_CREDITO + :NEW.PAY_VALUETOTAL,
                AC.COUNT_SALDO = AC.COUNT_SALDO - :NEW.PAY_VALUETOTAL
            WHERE AC.COUNT_ID = :OLD.PAY_ACCOUNT_ID;
            
       ELSIF :NEW.PAY_STATE = -1 AND :OLD.PAY_STATE  != -1 THEN
          
          -- Repor o valor da conta do banco
          UPDATE T_ACCOUNT CB
             SET CB.COUNT_CREDITO = CB.COUNT_CREDITO - :OLD.PAY_VALUETOTAL,
                 CB.COUNT_SALDO = CB.COUNT_SALDO + :OLD.PAY_VALUETOTAL
             WHERE CB.COUNT_ID = conta.COUNT_ID;
             
          -- Desativar todos os item do pagamento
          UPDATE T_ITEMPAYMENT IP
             SET IP.IPAY_STATE = -1 
             WHERE IP.IPAY_PAY_ID = :OLD.PAY_ID;
        
         -- Se o pagamento for por via de cheque entao a sequencia de cheque devera ser reposta
         IF :OLD.PAY_OBJ_FORMAPAYMENT = 2 THEN
         
             -- Carregar o talao do cheque utilizado no acto do registro do cheque
             -- Tem de ser o cheque ligado a conta onde foi elaborado o pagamento
             -- Quanto ao tipo do cheque devera ser do mesmo tipo do tempo que o pagamento registrado (1)
             SELECT * INTO cheque
               FROM T_CHEQUE CH
               WHERE CH.CHEQUE_ACCOUNT_ID = :OLD.PAY_ACCOUNT_ID
                  AND CH.CHEQUE_TIME = :OLD.PAY_TIME
                  AND(:OLD.PAY_TIME = 1
                          AND TO_NUMBER(:OLD.PAY_CHEQUE) 
                             BETWEEN TO_NUMBER(CH.CHEQUE_SEQINICIO) AND TO_NUMBER(CH.CHEQUE_SEQFIM) 

                          -- Ou entao se o tempo do pagamento for antigo entao siginifica que foi o cheque default do tempo antigo usado
                          OR (:OLD.PAY_TIME = 0  
                              AND TO_NUMBER(CH.CHEQUE_SEQINICIO) = -1  
                              AND TO_NUMBER(CH.CHEQUE_SEQFIM) = -1))
                  ;
                  
             -- Para todos o cheques devera diminuir a quantidade totol dos cheque utilizados
             UPDATE T_CHEQUE  CH
               SET CH.CHEQUE_STATE = (CASE WHEN CH.CHEQUE_TIME = 0 THEN CH.CHEQUE_STATE ELSE 1 END),
                   CH.CHEQUE_TTDESTRIBUIDO = CH.CHEQUE_TTDESTRIBUIDO - 1
               WHERE CH.CHEQUE_ID = cheque.CHEQUE_ID;
           
             -- Apenas se for um passado  diminuir a quantidade do cheque
             IF :OLD.PAY_TIME = 0 THEN
                UPDATE T_CHEQUE CH
                   SET CH.CHEQUE_TTCHEQUE = CH.CHEQUE_TTCHEQUE -1
                   WHERE CH.CHEQUE_ID = cheque.CHEQUE_ID;
             END IF;
             
            
          END IF;
       END IF;
    END IF;
END;