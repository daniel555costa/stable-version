create PACKAGE BODY PACK_REPORT2 AS

  FUNCTION FUNCT_REPORT_SINISTRO(dateInicio DATE, dateFim date) RETURN PACK_TYPE.filterReportSinistro PIPELINED AS
  BEGIN
     
     /*
        TYPE reportSinistro IS RECORD("ID" NUMBER, "REGISTRO" VARCHAR2(25), "SEGURO"VARCHAR2(60), 
        "APOLICE" VARCHAR(30) , "CLIENTTE" VARCHAR(120), "DATA" CHARACTER VARYING(20), "LOCAL OCORENCIA" VARCHAR(50), 
        "LOCAL INSPENSAO" VARCHAR2(50),"DATA INSPECAO" VARCHAR2(50)); 
        TYPE filterReportSinistro IS TABLE OF reportSinistro;
     */
       FOR I IN (SELECT (CASE 
                            WHEN OC.OCOR_OCOR_ID IS NOT NULL THEN OC.OCOR_OCOR_ID
                            ELSE OC.OCOR_ID
                         END) AS "ID", 
                       TO_CHAR(OC.OCOR_DTREG, 'DD-MM-YYYY') AS "REGISTRO",
                       OC.OCOR_COD AS "CODIGO",
                       SE.SEG_CODIGO AS "SEGURO",
                       CTT.CTT_NUMAPOLICE AS "APOLICE",
                       CL.CLI_NOME ||' '||CL.CLI_APELIDO AS "CLIENTE",
                       TO_CHAR(OC.OCOR_HORA, 'DD-MM-YYYY HH:MI:SS') AS "DATA",
                       LOCALL.OBJT_DESC AS "LOCAL OCORENCAI",
                       LOCAL_INSPECAO.OBJT_DESC AS "LOCAL INSPENCAO",
                       TO_CHAR(OC.OCOR_DTINSPECAO, 'DD-MM-YYYY') AS "DATA INSPENCAO",
                       CASE
                          WHEN OC.OCOR_STATE = 1 THEN 'Pendente'
                          WHEN OC.OCOR_STATE = 2 THEN 'Pago'
                          WHEN OC.OCOR_STATE = 0 THEN 'Anulado'
                          WHEN OC.OCOR_STATE = 3 THEN 'Pagamento solicitado'
                      END AS "ESTADO",
                      OC.OCOR_STATE
                       
                   FROM T_OCORRENCIA OC
                      INNER JOIN T_CONTRATO CTT ON OC.OCOR_CTT_ID = CTT.CTT_ID
                      INNER JOIN T_SEGURO SE ON CTT.CTT_SEG_ID = SE.SEG_ID
                      INNER JOIN T_CLIENTE CL ON CTT.CTT_CLI_ID = CL.CLI_ID
                      INNER JOIN T_OBJECTYPE LOCALL ON OC.OCOR_OBJT_LOCAL = LOCALL.OBJT_ID
                      INNER JOIN T_OBJECTYPE LOCAL_INSPECAO ON OC.OCOR_OBJT_LOCALINSPECAO = LOCAL_INSPECAO.OBJT_ID
                   WHERE  OC.OCOR_STATE != -1
                      AND (OC.OCOR_HORA BETWEEN dateInicio AND dateFim 
                             OR dateInicio IS NULL AND dateFim IS NULL)
                   ORDER BY OC.OCOR_DTREG DESC)
      LOOP
          PIPE ROW(I);
      END LOOP;
  END FUNCT_REPORT_SINISTRO;
  
  
  
  
  FUNCTION FUNCT_REPORT_PROVISAO (dataInicio DATE, dateFim date, idSeguro NUMBER) RETURN PACK_TYPE.filterReportProvisao PIPELINED 
  IS
      TYPE ListKey IS TABLE OF VARCHAR2(1000) INDEX BY VARCHAR2(1000) ;
      TYPE HasMap IS TABLE OF  PACK_TYPE.reportProvisao INDEX BY VARCHAR2(1000);
      currentReport  PACK_TYPE.reportProvisao;
      sigla CHARACTER VARYING(1000);
      
      keysIndex ListKey;
      mapValues HasMap ;
       
      provisao PACK_TYPE.reportProvisao;
      total PACK_TYPE.reportProvisao;
      sumTotal FLOAT := 0;
      sumPrimio float :=0;
      sumProvisao_10 FLOAT := 0;
      sumProvisao_30 FLOAT := 0;
      subTotal FLOAT;
      provisao_10 FLOAT;
      provisao_30 FLOAT;
      numDay NUMBER;
  BEGIN
  
      currentReport."NUMERO DEBITO" := 'TOTAL';
      currentReport."SEGURADO" := 'TOTAL';
      currentReport."PREMIO LIQUIDO" := 0;
      currentReport."PROVISAO 10%" := 0;
      currentReport."PROVISAO 30%" := 0;
      currentReport."TOTAL" := 0;
      mapValues('TOTAL') := currentReport;
     
     FOR CT IN (SELECT *
                  FROM T_CONTRATO CT
                     INNER JOIN T_CLIENTE CL ON CT.CTT_CLI_ID = CL.CLI_ID
                     INNER JOIN T_SEGURO SE ON  CT.CTT_SEG_ID = SE.SEG_ID
                     INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CT.CTT_DTREG, CT.CTT_MOE_ID)) TAX ON 1 = 1
                  WHERE CT.CTT_CTT_ID IS NULL
                     AND CT.CTT_SEG_ID != 3
                     AND 1 = (CASE 
                                WHEN dataInicio IS NULL OR dateFim IS NULL THEN 1
                                WHEN CAST(CT.CTT_DTCONTRATO AS DATE) BETWEEN dataInicio AND dateFim THEN 1
                                ELSE 0
                            END)
                        AND 1 = (CASE
                                    WHEN idSeguro IS NULL THEN 1
                                    WHEN idSeguro = CT.CTT_SEG_ID THEN 1
                                    ELSE 0
                                 END))
     LOOP
      /*
      TYPE reportProvisao IS RECORD
         -> "ID" NUMBER, 
         -> "NUMERO DEBITO" CHARACTER VARYING(50),
         -> "SEGURADO" CHARACTER VARYING (160),
         -> "PREMIO LIQUIDO" CHARACTER VARYING(120),
         -> "DATA INICIO" CHARACTER VARYING(20),
         -> "DATA FIM" CHARACTER VARYING(20),
         -> "PROVISAO 10%" CHARACTER VARYING(120),
         -> "PROVISAO 30%" CHARACTER VARYING(120),
         -> "TOTAL" CHARACTER VARYING (120),
         -> "SEGURO" CHARACTER VARYING(200));
    TYPE filterReportProvisao IS TABLE OF reportProvisao;
    
      */
        IF NOT keysIndex.EXISTS(CT."SEG_NOME") THEN
              keysIndex(CT."SEG_NOME") := CT."SEG_NOME";
              currentReport."NUMERO DEBITO" := 'TOTAL';
              currentReport."SEGURADO" := CT."SEG_NOME";
              
              currentReport."PREMIO LIQUIDO" := 0;
              currentReport."PROVISAO 10%" := 0;
              currentReport."PROVISAO 30%" := 0;
              currentReport."TOTAL" := 0;
              mapValues(CT."SEG_NOME") := currentReport;
        END IF;
        
        
        
        provisao_30 := 0;
        provisao_10 := 0;
        numDay := CT.CTT_DTFIM - CT.CTT_DTINICIO;
        
        IF numDay >= 365 THEN
           provisao_30 := (CT.CTT_VPAGAR * CT.TX_VENDA) * 0.3;
        ELSE
           provisao_10 := (CT.CTT_VPAGAR * CT.TX_VENDA) * 0.1;
        END IF;
        subTotal := provisao_30  + provisao_10;
        
        currentReport := mapValues(CT."SEG_NOME");
        currentReport."TOTAL" := currentReport."TOTAL" + subTotal;
        currentReport."PROVISAO 10%" := currentReport."PROVISAO 10%" + provisao_10;
        currentReport."PROVISAO 30%" := currentReport."PROVISAO 30%" + provisao_30;
        currentReport."PREMIO LIQUIDO" := currentReport."PREMIO LIQUIDO" + (CT.CTT_VPAGAR * CT.TX_VENDA);
        mapValues(CT."SEG_NOME") := currentReport;
        
        
        currentReport := mapValues('TOTAL');
        currentReport."TOTAL" := currentReport."TOTAL" +  subTotal;
        currentReport."PROVISAO 10%" := currentReport."PROVISAO 10%" + provisao_10;
        currentReport."PROVISAO 30%" := currentReport."PROVISAO 30%" + provisao_30;
        currentReport."PREMIO LIQUIDO" := currentReport."PREMIO LIQUIDO" + (CT.CTT_VPAGAR * CT.TX_VENDA);
         mapValues('TOTAL') := currentReport;
       
        provisao."ID" := CT.CTT_ID;
        provisao."NUMERO DEBITO" := CT.CTT_EXTERNALCOD;
        provisao."SEGURADO" := CT.CLI_NOME;
        IF CT.CLI_TCLI_ID = 1 THEN 
           provisao."SEGURADO" := CT.CLI_NOME||' '||CT.CLI_APELIDO;
        END IF;    
      
        provisao."PREMIO LIQUIDO" := PACK_LIB.money(CT.CTT_VPAGAR * CT.TX_VENDA)/*||' STD'*/;
        provisao."DATA INICIO" := TO_CHAR(CT.CTT_DTINICIO, 'DD-MM-YYYY');
        provisao."DATA FIM" := TO_CHAR(CT.CTT_DTFIM, 'DD-MM-YYYY');
        provisao."PROVISAO 10%" := PACK_LIB.MONEY(provisao_10)/*||' STD'*/;
        provisao."PROVISAO 30%" := PACK_LIB.MONEY(provisao_30)/*||' STD'*/;
        provisao."TOTAL" := PACK_LIB.MONEY(subTotal)/*||' STD'*/;
        provisao."SEGURO" := CT.SEG_NOME;
        
        PIPE ROW(provisao);
     END LOOP;
     
      sigla  := mapValues.FIRST;
        
      WHILE sigla IS NOT NULL LOOP
         
         IF sigla = 'TOTAL' THEN
            sigla := mapValues.NEXT(sigla);
            CONTINUE;
         END IF;
         
         currentReport := mapValues(sigla);
         currentReport."PREMIO LIQUIDO" := PACK_LIB.MONEY(currentReport."PREMIO LIQUIDO")||' STD';
         currentReport."PROVISAO 10%"  := PACK_LIB.MONEY(currentReport."PROVISAO 10%" )||' STD';
         currentReport."PROVISAO 30%" := PACK_LIB.MONEY(currentReport."PROVISAO 30%")||' STD';
         currentReport."TOTAL" := PACK_LIB.MONEY(currentReport."TOTAL")||' STD';
         PIPE ROW(currentReport);
         sigla := mapValues.NEXT(sigla);
      END LOOP;
      
      
      currentReport := mapValues('TOTAL');
      currentReport."PREMIO LIQUIDO" := PACK_LIB.MONEY(currentReport."PREMIO LIQUIDO")/*||' STD'*/;
      currentReport."PROVISAO 10%"  := PACK_LIB.MONEY(currentReport."PROVISAO 10%" )/*||' STD'*/;
      currentReport."PROVISAO 30%" := PACK_LIB.MONEY(currentReport."PROVISAO 30%")/*||' STD'*/;
      currentReport."TOTAL" := PACK_LIB.MONEY(currentReport."TOTAL")/*||' STD'*/;
      PIPE ROW(currentReport);     
  END;
  
  
  FUNCTION reportMovimentacaoConsumivel(dataInicio DATE, dataFim DATE) RETURN PACK_TYPE.filterMovimentacaoConsumivel PIPELINED
  IS 
  BEGIN
     --TYPE movimentacaoConsumivel IS RECORD 
     -- ("DATA" CHARACTER VARYING (20), 
     -- "CONSUMIVEL" CHARACTER VARYING(150), 
     -- "TIPO MOVIMENTACAO" CHARACTER VARYING(50), 
     -- "QUANTIDADE" NUMBER, 
     -- "ORIGEM/DESTINO" CHARACTER VARYING(200), 
     -- "FUNCIONARIO" CHARACTER VARYING(200), 
     -- "OBSERVACAO" CHARACTER VARYING(500));
    -- TYPE filterMovimentacaoConsumivel IS TABLE OF movimentacaoConsumivel;
    
    FOR I IN(SELECT IMOV.ITEMOV_ID AS "ID",
                    TO_CHAR(IMOV.ITEMOV_DTREG, 'DD-MON-YYYY') AS "DATA",
                    IT.ITEM_NAME AS "ITEM",
                    TIMOV.TITEMOV_DESC AS "TIPO MOVIMENTO",
                    IMOV.ITEMOV_QUANTITY AS "QUANTIDADE",
                    CASE 
                       WHEN IMOV.ITEMOV_SOURCEDESTIANTION  IS NOT NULL THEN IMOV.ITEMOV_SOURCEDESTIANTION 
                       ELSE 'N/A'
                    END AS "ORIGEM/DESTINO",
                    FUN.FUNC_NOME AS "NOME",
                    CASE
                       WHEN IMOV.ITEMOV_OBS IS NULL THEN 'N/A'
                       ELSE IMOV.ITEMOV_OBS
                    END AS "OBS"
                FROM T_ITEMOVIMENTATION IMOV
                   INNER JOIN T_ITEM IT ON IMOV.ITEMOV_ITEM_ID = IT.ITEM_ID
                   INNER JOIN T_TYPEITEMOVIMENT TIMOV ON IMOV.ITEMOV_TITEMOV_ID = TIMOV.TITEMOV_ID
                   INNER JOIN T_FUNCIONARIO FUN ON IMOV.ITEMOV_FUNC_ID = FUN.FUNC_ID
                WHERE (IMOV.ITEMOV_DTREG BETWEEN dataInicio AND dataFim
                        OR dataInicio IS NULL AND dataFim IS NULL)
                )
    LOOP
       PIPE ROW(I);
    END LOOP;
  END;
  
  
   FUNCTION reportFuncionario RETURN PACK_TYPE.filterReportFuncionario PIPELINED
   IS
   BEGIN
      /*
       TYPE reportFuncionario IS RECORD 
       ("ID" NUMBER, 
       "NOME" CHARACTER VARYING(200), 
       "FUNCAO" CHARACTER VARYING(150),
       "DEPARTAMENTO" CHARACTER VARYING(120),
       "CONTACTO" CHARACTER VARYING(200),
       "CONTA" CHARACTER VARYING(30),
       "BANCO" CHARACTER VARYING(200));
       TYPE filterReportFuncionario IS TABLE OF reportFuncionario;
      */
      FOR I IN (SELECT
                      FUN.FUNC_ID AS "ID",
                      FUN.FUNC_CODSEGURADORA,
                      FUN.FUNC_NOME||' '||FUN.FUNC_APELIDO AS "NOME",
                      CAT.OBJT_DESC AS CATEGORIA,
                      DEP.DEP_DESC AS "DEPARTAMENTO",
                      LFUN.LFUNC_MOVEL AS "CONTACO",
                      AC.COUNT_NIB AS "ACCOUNT",
                      BK.BK_SIGLA AS "BANCO"
                      
                      
                   FROM T_FUNCIONARIO FUN
                      INNER JOIN T_LINHAFUNCIONARIO LFUN ON FUN.FUNC_ID = LFUN.LFUNC_FUNC_ID
                      INNER JOIN T_OBJECTYPE CAT ON LFUN.LFUNC_CAT_ID = CAT.OBJT_ID
                      INNER JOIN T_DEPARTAMENTO DEP ON FUN.FUNC_DEP_ID = DEP.DEP_ID
                      INNER JOIN T_ACCOUNT AC ON FUN.FUNC_ID =  AC.COUNT_FUNC_ID
                      INNER JOIN T_BANK BK ON AC.COUNT_BK_ID = BK.BK_ID
                   )
      LOOP
          PIPE ROW(I);
      END LOOP;
   END;
   
   
   
   FUNCTION reportBalancete (dateInicio DATE, dateFim DATE) RETURN pack_type.filterBalancete PIPELINED
    IS
        balanceteAccount pack_type.reportBalancete;
        totalBanlancete pack_type.reportBalancete;
        totalResultado pack_type.reportBalancete;
        totalBalanco pack_type.reportBalancete;
        totalMoeda pack_type.reportBalancete;
        
        
        -- 
        PROCEDURE initReportBanlancete(balancete IN OUT pack_type.reportBalancete)
        IS 
        BEGIN
           balancete."DEBITO" := 0;
           balancete."CEDITO" := 0;
           balancete."DEVEDOR" := 0;
           balancete."CREDOR" := 0;
        END;
        
        -- 
        PROCEDURE collectValue (balanceteCollector IN OUT pack_type.reportBalancete, accoutBalancete pack_type.reportBalancete)
        IS
        BEGIN
           balanceteCollector."DEBITO" := totalBanlancete."DEBITO" + accoutBalancete."DEBITO";
           balanceteCollector."CEDITO" := totalBanlancete."CEDITO"  + accoutBalancete."CEDITO";
           balanceteCollector."DEVEDOR" := totalBanlancete."DEVEDOR" + accoutBalancete."DEVEDOR";
           balanceteCollector."CREDOR" := totalBanlancete."CREDOR" + accoutBalancete."CREDOR" ;
        END;
        
        PROCEDURE balanceteAsMoney(balancete IN OUT pack_type.reportBalancete)
        IS
        BEGIN
           balancete."DEBITO" := PACK_LIB.MONEY(balancete."DEBITO")/*||' STD'*/;
           balancete."CEDITO" := PACK_LIB.MONEY(balancete."CEDITO")/*||' STD'*/;
           balancete."DEVEDOR" := PACK_LIB.MONEY(balancete."DEVEDOR")/*||' STD'*/;
           balancete."CREDOR" := PACK_LIB.MONEY(balancete."CREDOR")/*||' STD'*/;
        END;
      
    BEGIN
       initReportBanlancete(totalBanlancete);
       initReportBanlancete(totalResultado);
       initReportBanlancete(totalBalanco);
       
       --Quando for informado uma lista de contas a ser apresentado entao preparar a lista
       
       
       IF dateInicio IS NOT NULL AND dateFim IS NOT NULL THEN
       
           FOR CONTAS IN (SELECT
                            CONTAS."ID",
                            CONTAS."COD",
                            CONTAS."DESC",
                            CONTAS."TP",
                            -- =================== PARA AS CONTA DE PAGAMENTOS (PAGAMENTOS) =================================
                            -- Carregar os somatorios de todos os pagamentos feitos para a conta
                            CASE 
                               WHEN CONTAS."TP" = 'P' THEN
                                  (SELECT SUM(IPAY.IPAY_VALUE * TAXA.TX_VENDA) 
                                            FROM T_ITEMPAYMENT IPAY
                                               INNER JOIN T_PAYMENT PAY ON IPAY.IPAY_PAY_ID = PAY.PAY_ID
                                               INNER JOIN T_ACCOUNT AC ON PAY.PAY_ACCOUNT_ID = AC.COUNT_ID
                                               INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(IPAY.IPAY_DTREG, AC.COUNT_MOE_ID)) TAXA ON 1 = 1
                                            WHERE IPAY.IPAY_ACCOUNT_ID = CONTAS."ID"
                                               AND CAST(IPAY.IPAY_DTREG AS DATE) BETWEEN dateInicio AND dateFim)
                               ELSE 0
                            END AS "PAGAMENTO CREDITO",
                            
                            -- =================== PARA AS CONTAS DO BANCO (AMORTIZACAO, PAGAMNETO, MOVIMENTACAO BANCARIS) ====================
                            -- Carregar o somatorio de todas as amortizaçoes feitas na conta (AMORTIZACAO AS PAYMETE OF PRESTATION)
                            CASE 
                               WHEN CONTAS."TP" = 'B' THEN
                                   (SELECT SUM(AMORT_VALOR * TAXA.TX_VENDA) 
                                            FROM T_AMORTIZACAO AM 
                                               INNER JOIN T_ACCOUNT AC ON AM.AMORT_ACCOUNT_ID = AC.COUNT_ID
                                               INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(AM.AMORT_DTREG, AC.COUNT_MOE_ID)) TAXA ON 1 = 1
                                            WHERE AM.AMORT_ACCOUNT_ID = CONTAS."ID"
                                               AND CAST(AM.AMORT_DTREG AS DATE) BETWEEN dateInicio AND dateFim)
                               ELSE 0
                            END AS "BANCO AMORTIZACAO",
                            
                            --Carregar o somatorio de todos os "<BR>PAGAMENTO<\BR>" feitos com a conta
                            CASE 
                               WHEN CONTAS."TP" = 'B' THEN
                                   (SELECT SUM(PAY.PAY_VALUETOTAL * TAXA.TX_VENDA)
                                       FROM T_PAYMENT PAY
                                          INNER JOIN T_ACCOUNT AC ON PAY.PAY_ACCOUNT_ID = AC.COUNT_ID
                                          INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(PAY.PAY_DTREG, AC.COUNT_MOE_ID)) TAXA ON 1 = 1
                                       WHERE PAY.PAY_ACCOUNT_ID = CONTAS."ID"
                                          AND CAST(PAY.PAY_DTREG AS DATE) BETWEEN dateInicio AND dateFim)
                               ELSE  0
                            END AS "BANCO PAGAMENTO",
                            
                            -- Carregar o somatorio de tadas as movimentações que a conta teve como "CREDITO"
                            CASE
                               WHEN CONTAS."TP" = 'B' THEN
                                  (SELECT SUM(MOV.MOV_VALOR * TAXA.TX_VENDA)
                                      FROM T_MOVIMENT MOV
                                         INNER JOIN T_ACCOUNT AC ON MOV.MOV_COUNT_DESTINATION = AC.COUNT_ID
                                         INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(MOV.MOV_DTREG, AC.COUNT_MOE_ID)) TAXA ON 1 =1
                                      WHERE MOV.MOV_COUNT_DESTINATION = CONTAS."ID"
                                         AND (CAST(MOV.MOV_DTREG AS DATE) BETWEEN dateInicio AND dateFim))
                               ELSE 0
                            END AS "BANCO MOV CREDITO",
                            
                            
                            -- Carregar o somatorio de tadas as movimentações que a conta teve como "DEBITO"
                            CASE
                               WHEN CONTAS."TP" = 'B' THEN
                                  (SELECT SUM(MOV.MOV_VALOR * TAXA.TX_VENDA)
                                      FROM T_MOVIMENT MOV
                                         INNER JOIN T_ACCOUNT AC ON MOV.MOV_COUNT_SOURCE = AC.COUNT_ID
                                         INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(MOV.MOV_DTREG, AC.COUNT_MOE_ID)) TAXA ON 1 =1
                                      WHERE MOV.MOV_COUNT_SOURCE = CONTAS."ID"
                                         AND ( CAST(MOV.MOV_DTREG AS DATE) BETWEEN dateInicio AND dateFim))
                               ELSE 0
                            END AS "BANCO MOV DEBITO"
                            
                         FROM VER_ALL_ACCOUNT CONTAS
                        ORDER BY CONTAS."COD" ASC)
           LOOP
               /*
                ("CONTA" VARCHAR(30), 
                "DESIGNACAO" VARCHAR2(100), 
                "DEBITO" VARCHAR2(120), 
                "CEDITO" VARCHAR2(120), 
                "DEVEDOR" VARCHAR2(120),
                "CREDOR" VARCHAR2(130));
                ----------- --------------
                "PAGAMENTO CREDITO" -> P
                "BANCO AMORTIZACAO" -> B
                "BANCO PAGAMENTO"   -> B
                "BANCO MOV DEBITO"  -> B
                "BANCO MOV CREDITO" -> B
               */
               
               -- Caso algum resultado esteja nulo entao forca-lo a ser 0
               IF CONTAS."PAGAMENTO CREDITO" IS NULL THEN CONTAS."PAGAMENTO CREDITO" := 0; END IF;
               IF CONTAS."BANCO AMORTIZACAO" IS NULL THEN CONTAS."BANCO AMORTIZACAO" := 0; END IF;
               IF CONTAS."BANCO PAGAMENTO" IS NULL THEN CONTAS."BANCO PAGAMENTO" := 0; END IF;
               IF CONTAS."BANCO MOV DEBITO" IS NULL THEN  CONTAS."BANCO MOV DEBITO"  := 0; END IF;
               IF CONTAS."BANCO MOV CREDITO" IS NULL THEN CONTAS."BANCO MOV CREDITO" := 0; END IF;
               
               -- RESET ALL DATA
               initReportBanlancete(balanceteAccount);
               
               -- Setar o nome e a descrincao da conta
               balanceteAccount."CONTA" := CONTAS."COD";
               balanceteAccount."DESIGNACAO" := CONTAS."DESC";
               
               -- Clacular o debito e o credito da conta
               balanceteAccount."DEBITO" := CONTAS."BANCO MOV DEBITO" + CONTAS."BANCO PAGAMENTO";
               balanceteAccount."CEDITO" := CONTAS."PAGAMENTO CREDITO" + CONTAS."BANCO AMORTIZACAO" + CONTAS."BANCO MOV CREDITO";
               
               
               -- Efetuar o calculo do vededor da conta
               IF TO_NUMBER(balanceteAccount."DEBITO") > TO_NUMBER(balanceteAccount."CEDITO") THEN
                  balanceteAccount."DEVEDOR" := balanceteAccount."DEBITO"  - balanceteAccount."CEDITO";
               ELSE
                  balanceteAccount."DEVEDOR" := 0;
               END IF;
                
               
               -- Efetuar o calculo do credor da conta
               IF TO_NUMBER(balanceteAccount."CEDITO") > TO_NUMBER(balanceteAccount."DEBITO")  THEN
                  balanceteAccount."CREDOR" := balanceteAccount."CEDITO" - balanceteAccount."DEBITO";
               ELSE 
                  balanceteAccount."CREDOR" := 0;
               END IF;
               
               IF TO_NUMBER(balanceteAccount."CEDITO")  = TO_NUMBER(balanceteAccount."DEBITO")  THEN
                  balanceteAccount."CREDOR" :=   0;
                  balanceteAccount."DEVEDOR" := 0;
               END IF;
               
               /*
                  balanceteAccount pack_type.reportBalancete;
                  totalBanlancete pack_type.reportBalancete;
                  totalResultado pack_type.reportBalancete;
                  totalBalanco pack_type.reportBalancete;
               */
               
               --Aculular o total do balancete
               collectValue(totalBanlancete, balanceteAccount);
               CASE
                  -- Quando a conta for a conta de balanco entao acumular o valor no reporte do dalaco
                  WHEN pack_lib.charat(balanceteAccount."CONTA", 1) BETWEEN '1' AND '5' OR pack_lib.charat(balanceteAccount."CONTA", 1) = '8' THEN 
                     collectValue(totalBalanco, balanceteAccount);
                  -- Quando a conta for a conta resultado entao acumular  valor na conta resultado
                  WHEN pack_lib.charat(balanceteAccount."CONTA", 1) = '8' THEN
                     collectValue(totalResultado, balanceteAccount);
                  ELSE
                     NULL;
               END CASE;
               
               
               -- Calcular o total resultado quando a raiz da conta igual a 8
               
               
               balanceteAsMoney(balanceteAccount);
               
               PIPE ROW(balanceteAccount);
               
           END LOOP;
           
           balanceteAsMoney(totalBanlancete);
           balanceteAsMoney(totalResultado);
           balanceteAsMoney(totalBalanco);
           
           totalBalanco."CONTA" := 'TOTAL';
           totalBalanco."DESIGNACAO" := 'CONTAS BALANÇO';
           
           totalResultado."CONTA":='TOTAL';
           totalResultado."DESIGNACAO" := 'CONTAS RESULTADO';
           
           
           totalBanlancete."CONTA":='TOTAL';
           totalBanlancete."DESIGNACAO" := 'BALANCETE';
           
           
           FOR MOEDA IN(SELECT MD.MOE_ID, MD.MOE_SIGLA,
                            (SELECT SUM(IPAY.IPAY_VALUE) 
                                      FROM T_ITEMPAYMENT IPAY
                                         INNER JOIN T_PAYMENT PAY ON IPAY.IPAY_PAY_ID = PAY.PAY_ID
                                         INNER JOIN T_ACCOUNT AC ON PAY.PAY_ACCOUNT_ID = AC.COUNT_ID
                                      WHERE AC.COUNT_MOE_ID = MD.MOE_ID
                                         AND CAST(IPAY.IPAY_DTREG AS DATE) BETWEEN dateInicio AND dateFim) "PAGAMENTO CREDITO",
                            
                            -- =================== PARA AS CONTAS DO BANCO (AMORTIZACAO, PAGAMNETO, MOVIMENTACAO BANCARIS) ====================
                            -- Carregar o somatorio de todas as amortizaçoes feitas na conta (AMORTIZACAO AS PAYMETE OF PRESTATION)
                            
                             (SELECT SUM(AMORT_VALOR * TAX.TX_VENDA) 
                                      FROM T_AMORTIZACAO AM 
                                         INNER JOIN T_ACCOUNT AC ON AM.AMORT_ACCOUNT_ID = AC.COUNT_ID
                                         INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(AM.AMORT_DTREG, AC.COUNT_MOE_ID)) TAX ON 1 = 1
                                      WHERE AC.COUNT_MOE_ID = MD.MOE_ID
                                         AND CAST(AM.AMORT_DTREG AS DATE) BETWEEN dateInicio AND dateFim)"BANCO AMORTIZACAO",
                            
                            --Carregar o somatorio de todos os "<BR>PAGAMENTO<\BR>" feitos com a moeda
                      
                             (SELECT SUM(PAY.PAY_VALUETOTAL * TAX.TX_VENDA)
                                 FROM T_PAYMENT PAY
                                    INNER JOIN T_ACCOUNT AC ON PAY.PAY_ACCOUNT_ID = AC.COUNT_ID
                                    INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(PAY.PAY_DTREG, AC.COUNT_MOE_ID)) TAX ON 1 = 1
                                 WHERE AC.COUNT_MOE_ID = MD.MOE_ID
                                    AND CAST(PAY.PAY_DTREG AS DATE) BETWEEN dateInicio AND dateFim) AS "BANCO PAGAMENTO",
                            
                            -- Carregar o somatorio de tadas as movimentações que a moeda teve como "CREDITO"
                            (SELECT SUM(MOV.MOV_VALOR)
                                FROM T_MOVIMENT MOV
                                   INNER JOIN T_ACCOUNT AC ON MOV.MOV_COUNT_DESTINATION = AC.COUNT_ID
                                WHERE AC.COUNT_MOE_ID = MD.MOE_ID
                                   AND (CAST(MOV.MOV_DTREG AS DATE) BETWEEN dateInicio AND dateFim)) AS "BANCO MOV CREDITO",
                            
                            
                            -- Carregar o somatorio de tadas as movimentações que a conta teve como "DEBITO"
                            (SELECT SUM(MOV.MOV_VALOR)
                                FROM T_MOVIMENT MOV
                                   INNER JOIN T_ACCOUNT AC ON MOV.MOV_COUNT_SOURCE = AC.COUNT_ID
                                WHERE AC.COUNT_MOE_ID = MD.MOE_ID
                                   AND ( CAST(MOV.MOV_DTREG AS DATE) BETWEEN dateInicio AND dateFim))  AS "BANCO MOV DEBITO"
                       FROM (SELECT DISTINCT MD.*
                                 FROM T_ACCOUNT AC
                                    INNER JOIN T_MOEDA MD ON AC.COUNT_MOE_ID = MD.MOE_ID) MD)
           LOOP
               
              -- Caso algum resultado esteja nulo entao forca-lo a ser 0
               IF MOEDA."PAGAMENTO CREDITO" IS NULL THEN MOEDA."PAGAMENTO CREDITO" := 0; END IF;
               IF MOEDA."BANCO AMORTIZACAO" IS NULL THEN MOEDA."BANCO AMORTIZACAO" := 0; END IF;
               IF MOEDA."BANCO PAGAMENTO" IS NULL THEN MOEDA."BANCO PAGAMENTO" := 0; END IF;
               IF MOEDA."BANCO MOV DEBITO" IS NULL THEN  MOEDA."BANCO MOV DEBITO"  := 0; END IF;
               IF MOEDA."BANCO MOV CREDITO" IS NULL THEN MOEDA."BANCO MOV CREDITO" := 0; END IF;
               
               -- RESET ALL DATA
               initReportBanlancete(totalMoeda);
               
               -- Setar o nome e a descrincao da conta
               totalMoeda."CONTA" := 'MOEDA';
               totalMoeda."DESIGNACAO" := MOEDA."MOE_SIGLA";
               
               -- Clacular o debito e o credito da conta
               totalMoeda."DEBITO" := MOEDA."BANCO MOV DEBITO" + MOEDA."BANCO PAGAMENTO";
               totalMoeda."CEDITO" := MOEDA."PAGAMENTO CREDITO" + MOEDA."BANCO AMORTIZACAO" + MOEDA."BANCO MOV CREDITO";
               
               
               -- Efetuar o calculo do vededor da conta
               IF TO_NUMBER(totalMoeda."DEBITO") > TO_NUMBER(totalMoeda."CEDITO") THEN
                  totalMoeda."DEVEDOR" := totalMoeda."DEBITO"  - totalMoeda."CEDITO";
               ELSE
                  totalMoeda."DEVEDOR" := 0;
               END IF;
                
               
               -- Efetuar o calculo do credor da conta
               IF TO_NUMBER(totalMoeda."CEDITO") > TO_NUMBER(totalMoeda."DEBITO")  THEN
                  totalMoeda."CREDOR" := totalMoeda."CEDITO" - totalMoeda."DEBITO";
               ELSE 
                  balanceteAccount."CREDOR" := 0;
               END IF;
               
               IF TO_NUMBER(totalMoeda."CEDITO")  = TO_NUMBER(totalMoeda."DEBITO")  THEN
                  totalMoeda."CREDOR" :=   0;
                  totalMoeda."DEVEDOR" := 0;
               END IF;
               
               balanceteAsMoney(totalMoeda);
               
               PIPE ROW(totalMoeda);
           END LOOP;
           
           PIPE ROW(totalBalanco);
           PIPE ROW(totalResultado);
           PIPE ROW(totalBanlancete);
        END IF;
    END;
    
    
    -- TYPE reportSalario IS RECORD ("ID" NUMBER, "CODIGO" VARCHAR2(100), "NOME" CHARACTER VARYING(200), "DIAS" NUMBER, "S.BASE" VARCHAR2(150), "S.ALOJAMENTO" CHARACTER VARYING(150), "S.TRANSPORTE" CHARACTER VARYING(150), "S.ALMOCO" CHARACTER VARYING(150),    -- TYPE filterReportSalario IS TABLE OF reportSalario;
    
    FUNCTION reportSalario(idProcess NUMBER) RETURN PACK_TYPE.FilterReportSalario PIPELINED
    IS
       salario PACK_TYPE.ReportSalario;
       totalSalario PACK_TYPE.ReportSalario;
       
      estruturaSalarial T_CATEGORY%ROWTYPE;
     salarioEstruturado FLOAT; -- CORRESPONDE AO SOMATORIO DE TODOS OS SALARIO DA ESTRUTURA DO SALARIO DO FUNCIONARIO
     bonusAlmoco FLOAT;  -- Corresponde a parte de salario que não se aplica imposto
     salarioSemBonus FLOAT;  -- Corresponde ao salario retirado a parte do bonus | ALIAS AS TRIBUTADO
     percentImpotoFuncionario FLOAT; -- Corresponde a percentagem do imposto do funcionario
     percentImpostoEmpresa FLOAT;  -- A percentagem do imposto que deve ser aplicado a empresa
     impAssisteSocialFuncionario FLOAT; -- Imposto que o funcionario deve pagar a assistencia social
     salarioImpostoFuncionario FLOAT;  -- O salario aplicado o impostod o funcionario
     
     /*COMISAO MENSAL DO FUNCIONARIO*/
     
     comisaoRow T_COMISAO%ROWTYPE;
     comisao FLOAT := 0; -- O valor da comisao do funcionario
     salarioComComisao FLOAT; -- Corresponde ao salario somado a comisao do mes do funcionario
     irsSalarioComisao T_IMPOSTOTAXA%ROWTYPE;  -- O IRS que sera aplicado ao funcionario
     percentagemIRS FLOAT; -- Corresponde a percentagem do irs que sera aplicado
     parcelaBaterIRS FLOAT; -- A parcela a bater do IRS a ser aplicado
     impostoIRS FLOAT; -- O valor do imposto do IRS que o funcionario devera pagar
     irsApurado FLOAT; -- Corresponde ao valor do IRS apurado (que sera o imposto do IRS retirandi a parcela a bater
     situacaoFamiliar T_SITUACAOFAMILIAR%ROWTYPE;
     salarioBaseNacional T_SALARIONACIONAL%ROWTYPE;
     valorSituacaoFamiliar FLOAT :=0; -- Corresponde ao valor da situação familiar
     irsLiquido FLOAT;
     salarioLiquido FLOAT; -- Corresponde ao salario aplicado as taxas do IRS
     
     salarioAvanco T_SALARIOAVANCO%ROWTYPE;
     avancoSalarial FLOAT :=0; -- Corresponde ao salario que o funcionario tera direito ao
     salarioFinal FLOAT; -- Correspinde oa real salario que o funcionario tem direito
     impAssisteSocialEmpresa FLOAT; -- Corresponde ao assistencia social da empresa
     salarioImpostoEmpresa FLOAT; -- COrresponde ao imposto da empresa
     
     taxaFuncionario T_IMPOSTOTAXA%ROWTYPE;
     taxaEmpresa T_IMPOSTOTAXA%ROWTYPE;
    
     /*
     "ID" NUMBER, 
     "CODIGO" VARCHAR2(100),
     "NOME" CHARACTER VARYING(200),
     "DIAS" NUMBER, 
     "S.BASE" VARCHAR2(150), 
     "S.ALOJAMENTO" CHARACTER VARYING(150), 
     "S.TRANSPORTE" CHARACTER VARYING(150), 
     "S.ALMOCO" CHARACTER VARYING(150), 
     "TT.SEM IMPOSTO" CHARACTER VARYING(150), 
     "ALMOCO LIVRE IMPOSTO" CHARACTER VARYING(150),
     "TRIBUTADO" CHARACTER VARYING (150), 
     "SS FUNCIONARIO" CHARACTER VARYING(150), 
     "MENOS SS FUNCIONARIO" CHARACTER VARYING(150), "COMISOES" CHARACTER VARYING(150),
     "TOTAL E COMISAO" CHARACTER VARYING(150), 
     "IRS" CHARACTER VARYING(150),
     "PARCELA BATER" CHARACTER VARYING(150),
     "IRS APURADO" CHARACTER VARYING(150), 
     "SITUA FAMILIAR" CHARACTER VARYING(150), 
     "IRS LIQUIDO" CHARACTER VARYING(150), 
     "ALMOCO" CHARACTER VARYING(150),
     "SALARIO LIQUIDO" CHARACTER VARYING(150), 
     "AVANCO" CHARACTER VARYING(150),
     "NET OUT" CHARACTER VARYING(150), 
     "SS EMPRESA" CHARACTER VARYING(150),
     "TOTAL" CHARACTER VARYING(150));
*/
      PROCEDURE clearRow(sal IN OUT PACK_TYPE.ReportSalario)
      IS
      BEGIN
        sal."ID" := NULL;
        sal."CODIGO" := NULL;
        sal."NOME" := NULL;
        sal."DIAS" := NULL;
        sal."S.BASE" := 0;
        sal."S.ALOJAMENTO" := 0;
        sal."S.TRANSPORTE" := 0;
        sal."S.ALMOCO" := 0;
        sal."TT.SEM IMPOSTO" := 0;
        sal."ALMOCO LIVRE IMPOSTO" := 0;
        sal."TRIBUTADO" := 0;
        sal."SS FUNCIONARIO" := 0;
        sal."MENOS SS FUNCIONARIO" := 0;
        sal."COMISOES" := 0;
        sal."TOTAL E COMISAO" := 0;
        sal."IRS" :=0;
        sal."PARCELA BATER" := 0;
        sal."IRS APURADO" := 0;
        sal."SITUA FAMILIAR" := 0;
        sal."IRS LIQUIDO" := 0;
        sal."ALMOCO" :=0;
        sal."SALARIO LIQUIDO" := 0;
        sal."AVANCO" := 0;
        sal."NET OUT" := 0;
        sal."SS EMPRESA" := 0;
        sal."TOTAL" := 0;
      END;
     
      PROCEDURE sumSalario(total IN OUT PACK_TYPE.ReportSalario, sal PACK_TYPE.ReportSalario)
      IS 
      BEGIN
          total."S.BASE" := total."S.BASE" + sal."S.BASE";
          total."S.ALOJAMENTO" := total."S.ALOJAMENTO" + sal."S.ALOJAMENTO";
          total."S.TRANSPORTE" := total."S.TRANSPORTE" + sal."S.TRANSPORTE" ;
          total."S.ALMOCO" := total."S.ALMOCO" + sal."S.ALMOCO" ;
          total."TT.SEM IMPOSTO" := total."TT.SEM IMPOSTO" + sal."TT.SEM IMPOSTO";
          total."ALMOCO LIVRE IMPOSTO" := total."ALMOCO LIVRE IMPOSTO" + sal."ALMOCO LIVRE IMPOSTO";
          total."TRIBUTADO" := total."TRIBUTADO" + sal."TRIBUTADO";
          total."SS FUNCIONARIO" := total."SS FUNCIONARIO" +  sal."SS FUNCIONARIO";
          total."MENOS SS FUNCIONARIO" := total."MENOS SS FUNCIONARIO" + sal."MENOS SS FUNCIONARIO";
          total."COMISOES" := total."COMISOES" + sal."COMISOES";
          total."TOTAL E COMISAO" := total."TOTAL E COMISAO" + sal."TOTAL E COMISAO";
          total."IRS" :=total."IRS" + sal."IRS";
          total."PARCELA BATER" := total."PARCELA BATER" + sal."PARCELA BATER";
          total."IRS APURADO" := total."IRS APURADO" + sal."IRS APURADO";
          total."SITUA FAMILIAR" := total."SITUA FAMILIAR" + sal."SITUA FAMILIAR";
          total."IRS LIQUIDO" := total."IRS LIQUIDO" + sal."IRS LIQUIDO";
          total."ALMOCO" := total."ALMOCO" + sal."ALMOCO";
          total."SALARIO LIQUIDO" := total."SALARIO LIQUIDO" + sal."SALARIO LIQUIDO";
          total."AVANCO" := total."AVANCO" + sal."AVANCO";
          total."SS EMPRESA" := total."SS EMPRESA" + sal."SS EMPRESA";
          total."NET OUT" := total."NET OUT" + sal."NET OUT";
          total."TOTAL" := total."TOTAL" + sal."TOTAL";
      END;
      
      PROCEDURE format(sal IN OUT PACK_TYPE.ReportSalario)
      IS
      BEGIN
        sal."S.BASE" := PACK_LIB.money(sal."S.BASE");
        sal."S.ALOJAMENTO" := PACK_LIB.money(sal."S.ALOJAMENTO");
        sal."S.TRANSPORTE" := PACK_LIB.money(sal."S.TRANSPORTE");
        sal."S.ALMOCO" := PACK_LIB.money(sal."S.ALMOCO");
        sal."TT.SEM IMPOSTO" := PACK_LIB.money(sal."TT.SEM IMPOSTO");
        sal."ALMOCO LIVRE IMPOSTO" := PACK_LIB.money(sal."ALMOCO LIVRE IMPOSTO");
        sal."TRIBUTADO" := PACK_LIB.money(sal."TRIBUTADO");
        sal."SS FUNCIONARIO" := PACK_LIB.money(sal."SS FUNCIONARIO");
        sal."MENOS SS FUNCIONARIO" := PACK_LIB.money(sal."MENOS SS FUNCIONARIO");
        sal."COMISOES" := PACK_LIB.money(sal."COMISOES");
        sal."TOTAL E COMISAO" := PACK_LIB.money(sal."TOTAL E COMISAO");
        sal."IRS" := PACK_LIB.money(sal."IRS");
        sal."PARCELA BATER" := PACK_LIB.money(sal."PARCELA BATER");
        sal."IRS APURADO" :=  PACK_LIB.money(sal."IRS APURADO" );
        sal."SITUA FAMILIAR" := PACK_LIB.money(sal."SITUA FAMILIAR");
        sal."IRS LIQUIDO" := PACK_LIB.money(sal."IRS LIQUIDO");
        sal."ALMOCO" := PACK_LIB.money(sal."ALMOCO");
        sal."SALARIO LIQUIDO" := PACK_LIB.money(sal."SALARIO LIQUIDO");
        sal."AVANCO" := PACK_LIB.money(sal."AVANCO");
        sal."NET OUT" := PACK_LIB.money(sal."NET OUT");
        sal."SS EMPRESA" := PACK_LIB.money(sal."SS EMPRESA");
        sal."TOTAL" := PACK_LIB.money(sal."TOTAL");
      END;
      
     
   BEGIN
      clearRow(totalSalario);
       /*
          reportSalario IS RECORD (
            -> "ID" NUMBER,
            -> "CODIGO" VARCHAR2(100),
            -> "NOME" CHARACTER VARYING(200),
            -> "DIAS" NUMBER,
             "S.BASE" VARCHAR2(150), 
             "S.ALOJAMENTO" CHARACTER VARYING(150),
             "S.TRANSPORTE" CHARACTER VARYING(150),
             "S.ALMOCO" CHARACTER VARYING(150), 
             "TT.SEM IMPOSTO" CHARACTER VARYING(150), 
             "ALMOCO LIVRE IMPOSTO" CHARACTER VARYING(150), 
       */
       
       FOR SA IN(SELECT *
                   FROM T_SALARIO SA
                      INNER JOIN T_FUNCIONARIO F ON SA.SAL_FUNC_ID = F.FUNC_ID
                      LEFT JOIN T_ACCOUNT AC ON F.FUNC_ID = AC.COUNT_FUNC_ID
                      LEFT JOIN T_BANK BK ON AC.COUNT_BK_ID = BK.BK_ID
                   WHERE SA.SAL_PROSAL_ID = idProcess)
       LOOP
          SELECT * INTO estruturaSalarial
             FROM T_CATEGORY CA
             WHERE CA.CAT_ID = SA.SAL_CAT_ID;
          
          clearRow(salario);
          salario."ID FUNCIONARIO" := SA.FUNC_ID;
          salario."DIAS" := estruturaSalarial.CAT_NUMDIAS;
          salario."ID" := SA.SAL_ID;
          salario."CODIGO" := 'NS'||LPAD(SA.SAL_ID, 4, '0');
          salario."NOME" := SA.FUNC_NOME||' '||SA.FUNC_APELIDO;
          salario."S.BASE" := estruturaSalarial.CAT_BASESALARY;
          salario."S.ALOJAMENTO" := estruturaSalarial.CAT_HOUSESUBVENTION;
          salario."S.TRANSPORTE" := estruturaSalarial.CAT_TRANSPORTSUBVENTION;
          salario."S.ALMOCO" := estruturaSalarial.CAT_LUNCHSUBVENTION;
          salario."ALMOCO LIVRE IMPOSTO" := estruturaSalarial.CAT_ALMOCOBONUS;
          salario."BANCO" := SA.BK_SIGLA;
          
          
            -- Calcular o somatorio da estrutura salarial do funcionario
          salarioEstruturado := estruturaSalarial.CAT_BASESALARY + estruturaSalarial.CAT_HOUSESUBVENTION
                                + estruturaSalarial.CAT_LUNCHSUBVENTION + estruturaSalarial.CAT_TRANSPORTSUBVENTION;
          salario."TT.SEM IMPOSTO" := salarioEstruturado;
          
          /*
          "TRIBUTADO" CHARACTER VARYING (150), 
          "SS FUNCIONARIO" CHARACTER VARYING(150), 
          "MENOS SS FUNCIONARIO" CHARACTER VARYING(150),
          "COMISOES" CHARACTER VARYING(150), 
          "TOTAL E COMISAO" CHARACTER VARYING(150), 
          */
          bonusAlmoco := estruturaSalarial.CAT_ALMOCOBONUS;
          IF bonusAlmoco IS NULL THEN 
              bonusAlmoco := 0;
          END IF;
          
          salarioSemBonus := salarioEstruturado - bonusAlmoco;
          salario."TRIBUTADO" := salarioSemBonus;
          
          SELECT * INTO taxaFuncionario
             FROM T_IMPOSTOTAXA IP 
             WHERE IP.IMPTAX_ID = SA.SAL_IMPTAX_FUNCIONARIO;
          
          percentImpotoFuncionario := taxaFuncionario.IMPTAX_PERCENTAGEM;
          impAssisteSocialFuncionario := (percentImpotoFuncionario/100) * salarioSemBonus;
          salarioImpostoFuncionario := salarioSemBonus - impAssisteSocialFuncionario;
          
          salario."SS FUNCIONARIO" := impAssisteSocialFuncionario;
          salario."MENOS SS FUNCIONARIO" := salarioImpostoFuncionario;
          
          IF SA.SAL_COMISAO_ID IS NOT NULL THEN
              SELECT * INTO comisaoRow
                 FROM T_COMISAO CO
                 WHERE CO.COMISAO_ID = SA.SAL_COMISAO_ID;
              comisao := comisaoRow.COMISAO_VALOR;
          ELSE 
              comisao := 0;
          END IF;
          
          
          salario."COMISOES" := comisao;
          
          salarioComComisao := salarioImpostoFuncionario + comisao;
          salario."TOTAL E COMISAO" := salarioComComisao;
          
          /*
          "IRS" CHARACTER VARYING(150), 
          "PARCELA BATER" CHARACTER VARYING(150),
          "IRS APURADO" CHARACTER VARYING(150)
          */
          SELECT * INTO irsSalarioComisao
             FROM T_IMPOSTOTAXA IRS 
             WHERE IRS.IMPTAX_ID = SA.SAL_IMPTAX_IRS;
          
           parcelaBaterIRS := irsSalarioComisao.IMPTAX_PARCELABATER;
           percentagemIRS := irsSalarioComisao.IMPTAX_PERCENTAGEM;
            
           impostoIRS := salarioComComisao * (percentagemIRS/100);
           irsApurado := impostoIRS - parcelabaterIRS;
           salario."IRS" := impostoIRS;
           
           salario."PARCELA BATER" := parcelaBaterIRS;
           salario."IRS APURADO" := irsApurado;
           
          IF SA.SAL_SITUA_ID IS NOT NULL AND SA.SAL_SALNACIO_ID IS NOT NULL THEN 
             SELECT * INTO situacaoFamiliar
                FROM  T_SITUACAOFAMILIAR SI 
                WHERE SI.SITUA_ID = SA.SAL_SITUA_ID;
                
             SELECT * INTO salarioBaseNacional
                  FROM T_SALARIONACIONAL SN
                     WHERE SN.SALNACIO_ID = SA.SAL_SALNACIO_ID;
                     
             -- TODO aqui é para aplicar o calculo de obter o valor da situacao familiar em relacao ao numeros de filos
             valorSituacaoFamiliar := (situacaoFamiliar.SITUA_VALORPAGAR/100) * salarioBaseNacional.SALNACIO_VALOR;
          ELSE
             valorSituacaoFamiliar := 0;
          END IF;
          
          /*
          "SITUA FAMILIAR" CHARACTER VARYING(150), 
          "IRS LIQUIDO" CHARACTER VARYING(150),
          "ALMOCO" CHARACTER VARYING(150), 
          "SALARIO LIQUIDO" CHARACTER VARYING(150), 
          "AVANCO" CHARACTER VARYING(150), 
          "NET OUT" CHARACTER VARYING(150), 
          */
          
          salario."SITUA FAMILIAR" := valorSituacaoFamiliar;
          
          irsLiquido  := irsApurado - valorSituacaoFamiliar;
          salarioLiquido := salarioComComisao - irsLiquido + bonusAlmoco;
          salario."IRS LIQUIDO" := irsLiquido;
          salario."ALMOCO" := bonusAlmoco;
          salario."SALARIO LIQUIDO" := salarioLiquido;
          -- salario."AVANCO" := 
          IF SA.SAL_AVANCO_ID IS NOT NULL THEN 
             SELECT * INTO salarioAvanco
                FROM T_SALARIOAVANCO AV
                WHERE AV.SALAVANCO_ID = SA.SAL_AVANCO_ID;
             avancoSalarial := salarioAvanco.SALAVANCO_VALOR;
          ELSE 
               avancoSalarial := 0;
          END IF;
          
          salario."AVANCO" := avancoSalarial;
          salarioFinal := salarioLiquido - avancoSalarial;
          salario."NET OUT" := salarioFinal;
          
          SELECT * INTO taxaEmpresa
             FROM T_IMPOSTOTAXA ITAXA 
             WHERE ITAXA.IMPTAX_ID = SA.SAL_IMPTAX_EMPRESA;
          
          percentImpostoEmpresa := taxaEmpresa.IMPTAX_PERCENTAGEM;
          impAssisteSocialEmpresa := salarioSemBonus * (percentImpostoEmpresa/100);
          salarioImpostoEmpresa := salarioEstruturado + impAssisteSocialEmpresa;
          
          /*
          "SS EMPRESA" CHARACTER VARYING(150), 
          "TOTAL" CHARACTER VARYING(150)
          */
          
          salario."SS EMPRESA" := impAssisteSocialEmpresa;
          salario."TOTAL" := salarioImpostoEmpresa;
          
          sumSalario(totalSalario, salario);
          salario."STATUS" := 'BRUTO';
          PIPE ROW(salario);
          format(salario);
          salario."STATUS" := 'FORMAT';
          PIPE ROW(salario);
       END LOOP;
       
       totalSalario."CODIGO" := 'TOTAL';
       totalSalario."STATUS" := 'BRUTO';
       PIPE ROW(totalSalario);
       format(totalSalario);
       totalSalario."STATUS" := 'FORMAT';
       PIPE ROW(totalSalario);
    END;
    
    
    FUNCTION reportSalarioTaxa(dataProcess DATE) RETURN PACK_TYPE.FilterReportSalarioTaxa PIPELINED
    IS
       process T_PROCESSALARY%ROWTYPE;
       salario PACK_TYPE.ReportSalarioTaxa;
       tt NUMBER;
    BEGIN
       -- TYPE ReportSalarioTaxa IS RECORD("TIPO TAXA" CHARACTER VARYING (100), "NOME" CHARACTER VARYING(100), "VALOR" CHARACTER VARYING(300));

       SELECT COUNT(*) INTO tt
          FROM  T_PROCESSALARY S
          WHERE TO_CHAR(S.PROSAL_DATA, 'YYYY-MM') = TO_CHAR(dataProcess, 'YYYY-MM')
             AND S.PROSAL_STATE IN (1, 2, 0);
      IF tt != 0 THEN
          SELECT * INTO process
             FROM  T_PROCESSALARY S
             WHERE TO_CHAR(S.PROSAL_DATA, 'YYYY-MM') = TO_CHAR(dataProcess, 'YYYY-MM')
                AND S.PROSAL_STATE IN (1, 2, 0)
                AND ROWNUM <= 1;
                
            
             
          FOR SAL IN(SELECT *
                      FROM TABLE(PACK_REPORT2.REPORTSALARIO(process.PROSAL_ID)) SAL
                      WHERE SAL."CODIGO" = 'TOTAL'
                         AND SAL."STATUS" = 'BRUTO')
          LOOP
             salario."TIPO TAXA" := 'SEGURACA SOCIAL';
             salario."NOME" := 'EMPRESA';
             salario."VALOR" := PACK_LIB.money(SAL."SS EMPRESA");
             PIPE ROW(salario);
             
             salario."NOME" := 'FUNCIONARIO';
             salario."VALOR" := PACK_LIB.money(SAL."SS FUNCIONARIO");
             PIPE ROW(salario);
             
              salario."NOME" := 'TOTAL';
             salario."VALOR" := PACK_LIB.money(SAL."SS FUNCIONARIO" + SAL."SS EMPRESA");
             PIPE ROW(salario);
             
             
             salario."TIPO TAXA" := 'IRS';
             salario."NOME" := 'TOTAL';
             salario."VALOR" := PACK_LIB.money(SAL."IRS LIQUIDO");
             PIPE ROW(salario);
          END LOOP;
            
         
      END IF;
          
    END;

END PACK_REPORT2;