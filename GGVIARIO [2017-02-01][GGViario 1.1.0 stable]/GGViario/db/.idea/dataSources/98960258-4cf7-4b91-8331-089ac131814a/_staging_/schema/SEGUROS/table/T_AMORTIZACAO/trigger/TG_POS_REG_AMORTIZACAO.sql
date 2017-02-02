create or REPLACE trigger TG_POS_REG_AMORTIZACAO
	after insert
	on T_AMORTIZACAO
	for each row
DECLARE
      infoPrestacao  T_PRESTACAO%ROWTYPE;
      infocontrato  T_CONTRATO%ROWTYPE;
      conversao DOUBLE PRECISION;
      taxaMoedaContrato T_TAXA%ROWTYPE;
      taxaMoedaConta T_TAXA%ROWTYPE;
      conta T_ACCOUNT%ROWTYPE;
      begin
        -- Carregra as informações da prestaçao a ser amortizada
        SELECT * INTO infoPRESTACAO 
            FROM T_PRESTACAO
            where prest_ID = :NEW.AMORT_PREST_ID;
        
        -- Carregar as informações do contratos
        SELECT * INTO infocontrato
          from T_CONTRATO 
          WHERE CTT_ID = infoPrestacao.PREST_CTT_ID;
          
       SELECT * INTO conta
          FROM T_ACCOUNT
          WHERE COUNT_ID = :NEW.AMORT_ACCOUNT_ID;
         
         -- Se o valor a aser amortizado mas os valores amortizados anteriormente forem igual ao valor total da prestação
           -- Seguinifica que a prestação ja esta paga por completo. Nesse caso a prestação sera desabilitada
         IF(:NEW.AMORT_VALOR + INFOPRESTACAO.PREST_VALORPAGO) = INFOPRESTACAO.PREST_VALOR THEN
                
                UPDATE T_PRESTACAO
                  SET PREST_VALORPAGO = (PREST_VALORPAGO +:NEW.AMORT_VALOR ),
                      PREST_DTINIC = (CASE WHEN INFOPRESTACAO.PREST_STATE = 2 THEN SYSDATE ELSE PREST_DTINIC END),
                      PREST_STATE = 1
                  WHERE prest_ID = :NEW.AMORT_PREST_ID;
          ELSE
          -- Caso a nova amortização juntamente com as antigas amortizações não pagar por completo a prestaçao 
            -- Sequinifica que essa amortização não foi suficiente para liquidar a prestacao por completo nesse caso a prestacao 
            -- deve entra do estado de pagamento e se esse for a primeira amortização da data inicio da amortizacao deve ser a tada autal
                UPDATE T_PRESTACAO
                  SET PREST_VALORPAGO = (PREST_VALORPAGO +:NEW.AMORT_VALOR ),
                      PREST_DTINIC = (CASE WHEN INFOPRESTACAO.PREST_STATE = 2 THEN SYSDATE ELSE PREST_DTINIC END),
                      PREST_DTFIM = SYSDATE,
                      prest_state = 0
                  WHERE prest_ID = :NEW.AMORT_PREST_ID  ;
          end if;
            
        -- Caso o valor da amortização juntamente com os valores amortizados anteriormente seja suficiente para liquidar a divida do contrato 
        -- Então nasse momento o estado do pagamento do contrado deve ser fechado
        if (:new.amort_valor + infocontrato.ctt_vpago)= infocontrato.ctt_vpagar then
            update t_contrato
              set ctt_vpago =(ctt_vpago + :new.amort_valor),
                ctt_paystate = 0
              where  CTT_ID = infoPrestacao.PREST_CTT_ID ;      
        else
        -- Se a nova amortização não for soficiente para amortizar o contrato então o contrato deve entrar no estado pagando
            update t_contrato
              set ctt_vpago =(ctt_vpago + :new.amort_valor),
                ctt_paystate = 1
              where  CTT_ID = infoPrestacao.PREST_CTT_ID ; 
        end if;   
        
           
        UPDATE T_ACCOUNT AC
           SET AC.COUNT_SALDO  = AC.COUNT_SALDO + :NEW.AMORT_VALUEACCOUNT,
               AC.COUNT_DEBITO = AC.COUNT_DEBITO + :NEW.AMORT_VALUEACCOUNT
           WHERE AC.COUNT_ID = :NEW.AMORT_ACCOUNT_ID;
        
    END;