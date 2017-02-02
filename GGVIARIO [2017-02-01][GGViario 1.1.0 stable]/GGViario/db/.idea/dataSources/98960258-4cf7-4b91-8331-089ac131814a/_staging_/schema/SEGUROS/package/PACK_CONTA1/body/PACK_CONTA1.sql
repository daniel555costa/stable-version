create PACKAGE BODY PACK_CONTA1 AS

  function func_preview_lancamento_seq return character VARYING AS
    lastId NUMBER;
  BEGIN
      SELECT MAX(LC.LANCA_ID)+1 into lastId
         FROM T_LANCAMENTO LC;
      
      IF lastId IS NULL THEN
         RETURN 1;
      END IF;
      return lastId;
      
  END func_preview_lancamento_seq;

  function func_reg_lancamento ( idUser NUMBER,
                                 idTypeLancamento NUMBER,
                                 ttContaLancamento NUMBER,
                                 dataLancamento DATE) return CHARACTER IS
    idLancamento NUMBER;
  BEGIN
     INSERT INTO T_LANCAMENTO (LANCA_DATA,
                               LANCA_TLANCA_ID,
                               LANCA_USER_ID,
                               LANCA_TTCONTA)
                               VALUES (dataLancamento,
                                       idTypeLancamento,
                                       idUser,
                                       ttContaLancamento) RETURNING LANCA_ID INTO idLancamento;
     RETURN 'true;'||idLancamento;
  END func_reg_lancamento;
  

  function func_reg_lancamentoaccount (idLancamento NUMBER, -- id devolvida da primeira funcao
                                       idUser NUMBER,
                                       idTypeMoviment NUMBER, -- 1 DEBITO| 2 - CREDITO
                                       idAccount NUMBER,
                                       idMoeda NUMBER,
                                       documentNumber CHARACTER VARYING,
                                       documentDesc CHARACTER VARYINg,
                                       documentData DATE,
                                       descrincao CHARACTER VARYING,
                                       valor FLOAT
                                       ) return CHARACTER VARYING AS
     valueSTD FLOAT := valor;
     valueAccount FLOAT := valor;
     moeda T_MOEDA%ROWTYPE;
     account T_ACCOUNT%ROWTYPE;
     lancamento T_LANCAMENTO%ROWTYPE;
     
     taxa T_TAXA%ROWTYPE;
     taxaMoedaConta T_TAXA%ROWTYPE;
     
  BEGIN
     SELECT * INTO moeda
        FROM T_MOEDA MD
        WHERE MD.MOE_ID = idMoeda;
        
     SELECT * INTO account
        FROM T_ACCOUNT AC
        WHERE AC.COUNT_ID = idAccount;
        
     SELECT * INTO lancamento
        FROM T_LANCAMENTO lc
        WHERE lc.LANCA_ID = idLancamento;
        
     SELECT * INTO taxa
        FROM TABLE(PACK_CONTA.GETTAXADAY(SYSTIMESTAMP, idMoeda));
        
    SELECT * INTO taxaMoedaConta
       FROM TABLE(PACK_CONTA.GETTAXAMONEY(SYSTIMESTAMP, idMoeda, account.COUNT_MOE_ID));
        
     
        
     -- Se a operacao nao for em moeda dobra entaca efetuar a conversao para a moeda de dobra
     IF moeda.MOE_SIGLA != 'STD' THEN
        valueSTD := valor * taxa.tx_venda;
     END IF;
     
     -- Se a moeda da operacao nao for igua a moeda da conta entao proucurar o cambio para a morda da conta
     IF account.COUNT_MOE_ID IS NOT NULL
        AND idMoeda != account.COUNT_MOE_ID THEN
        valueAccount := valor * taxaMoedaConta.TX_VENDA;
     END IF;
     
     INSERT INTO T_LANCAMENTOACCOUNT (LANCACOUNT_LANCA_ID,
                                      LANCACOUNT_USER_ID,
                                      LANCACOUNT_TMOV_ID,
                                      LANCACOUNT_ACCOUNT_ID,
                                      LANCACOUNT_MOE_ID,
                                      LANCACOUNT_DOCNUM,
                                      LANCACOUNT_DOCDATA,
                                      LANCACOUNT_DOCDESC,
                                      LANCACOUNT_MOVDESC,
                                      LANCACOUNT_VALUE,
                                      LANCACOUNT_VALUESTD,
                                      LANCACOUNT_VALUEACCOUNT)
                                      VALUES (idLancamento,
                                              idUser,
                                              idTypeMoviment,
                                              idAccount,
                                              idMoeda,
                                              documentNumber,
                                              documentData,
                                              documentDesc,
                                              descrincao,
                                              valor,
                                              valueSTD,
                                              valueAccount);
     RETURN 'true;Sucesso';
  END func_reg_lancamentoaccount;
  

  FUNCTION func_end_lancamento(idUser NUMBER,
                               idLancamento NUMBER) RETURN CHARACTER VARYING AS
                               
    lancamento T_LANCAMENTO%ROWTYPE;
    valorCredito FLOAT;
    valorDebito FLOAT;
  BEGIN
     
     -- Obter o somatorio de todos os debitos
     SELECT SUM(LCC.LANCACOUNT_VALUESTD) into valorDebito
        FROM T_LANCAMENTOACCOUNT LCC
        WHERE LCC.LANCACOUNT_LANCA_ID = idLancamento
           AND LCC.LANCACOUNT_TMOV_ID = 1;
           
     -- Obter o somatorio de todos os creditos
     SELECT SUM(LCC.LANCACOUNT_VALUESTD) into valorCredito
        FROM T_LANCAMENTOACCOUNT LCC
        WHERE LCC.LANCACOUNT_LANCA_ID = idLancamento
           AND LCC.LANCACOUNT_TMOV_ID = 2;
           
     IF valorCredito != valorDebito THEN  
        RETURN 'false;'||FUNC_ERROR('CREDITO!DEBITO');
     END IF;
     
     SELECT * INTO lancamento
        FROM T_LANCAMENTO lc
        WHERE lc.LANCA_ID = idLancamento;
        
      
     IF lancamento.LANCA_STATE = 2 THEN 
        -- Para toas as contas do lancameto debitar ao creditar o valor do seu respectivo credito ou debitp
        FOR LC IN(SELECT *
                   FROM T_LANCAMENTOACCOUNT LC
                   WHERE LC.LANCACOUNT_LANCA_ID = idLancamento) LOOP
           UPDATE T_ACCOUNT AC
              SET AC.COUNT_DEBITO = (CASE
                                        WHEN LC.LANCACOUNT_TMOV_ID = 1 THEN AC.COUNT_DEBITO + LC.LANCACOUNT_VALUEACCOUNT
                                        ELSE AC.COUNT_DEBITO
                                     END),
                  AC.COUNT_CREDITO = (CASE 
                                        WHEN LC.LANCACOUNT_TMOV_ID = 2 THEN AC.COUNT_CREDITO + LC.LANCACOUNT_VALUEACCOUNT
                                        ELSE AC.COUNT_CREDITO
                                      END)
              WHERE AC.COUNT_ID = LC.LANCACOUNT_ACCOUNT_ID
                  ;
        END LOOP;
        
        UPDATE T_LANCAMENTO LC
           SET LC.LANCA_STATE = 1,
               LC.LANCA_VALUETOTAL = (SELECT SUM(LCC.LANCACOUNT_VALUESTD)
                                         FROM T_LANCAMENTOACCOUNT LCC
                                         WHERE LCC.LANCACOUNT_LANCA_ID = idLancamento)
          WHERE LC.LANCA_ID = idLancamento;
     END IF;
        
    RETURN 'true;Sucesso';
  END func_end_lancamento;

END PACK_CONTA1;