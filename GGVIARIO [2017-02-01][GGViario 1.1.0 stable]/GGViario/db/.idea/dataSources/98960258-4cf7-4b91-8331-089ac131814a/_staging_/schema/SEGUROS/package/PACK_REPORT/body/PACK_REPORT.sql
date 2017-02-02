create PACKAGE BODY PACK_REPORT AS

      FUNCTION reportClient (idSeguro NUMBER,dataInicio DATE, dataFim DATE)
      RETURN PACK_TYPE.filterReportClient PIPELINED
      IS
        rowL PACK_TYPE.reportClients;
        totalTypo PACK_TYPE.reportClients;
        valorTota FLOAT := 0;
        uheru number;
    
      --  TYPE reportClient IS RECORD(CLIENTE VARCHAR2(120), "SEGURO FREQ" VARCHAR2(100), "PRIMEIRO CONTRATO", "QUANT" NUMBER, VARCHAR2(10), "TOTAL PREMIO" VARCHAR2(120));
      BEGIN
          FOR I IN (SELECT
                    CL.ID,
                    CL.NOME,
                    (SELECT SEG.SEG_NOME||' ('||SEG.TOTAL||')'
                          FROM(SELECT SE.SEG_NOME,
                                      CT.CTT_CLI_ID,
                                      COUNT(*) AS "TOTAL"
                                  FROM T_CONTRATO CT
                                      INNER JOIN T_SEGURO SE  ON CT.CTT_SEG_ID = SE.SEG_ID
                                  WHERE CT.CTT_NUMAPOLICE IS NOT NULL
                                     AND CT.CTT_SEG_ID = idSeguro OR idSeguro IS NULL
                                  GROUP BY SE.SEG_NOME,  CT.CTT_CLI_ID
                                  ORDER  BY TOTAL DESC) SEG
                          WHERE  ROWNUM <=1
                             AND SEG.CTT_CLI_ID = CL.ID
                          )  AS SEGURO,
      
                  (SELECT TO_CHAR(MIN(CT.CTT_DTCONTRATO), 'DD-MM-YYYY')
                      FROM T_CONTRATO CT 
                      WHERE CT.CTT_CLI_ID = CL.ID 
                         AND CT.CTT_CTT_ID IS NULL
                         AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1
                         AND (CT.CTT_SEG_ID = idSeguro  OR idSeguro IS NULL)
                         AND CT.CTT_NUMAPOLICE IS NOT NULL) AS FRIST,
       
                  (SELECT COUNT(*) 
                      FROM T_CONTRATO CT 
                      WHERE CT.CTT_CLI_ID = CL.ID 
                         AND CT.CTT_CTT_ID IS NULL
                         AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1
                         AND (CT.CTT_SEG_ID = idSeguro  OR idSeguro IS NULL)
                         AND CT.CTT_NUMAPOLICE IS NOT NULL) "QUANT",
                     
                  (SELECT (SUM(CT.CTT_VPAGAR * TAX.TX_VENDA))||'' 
                      FROM T_CONTRATO CT 
                         INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CT.CTT_DTCONTRATO, CT.CTT_MOE_ID)) TAX ON 1 = 1
                      WHERE CT.CTT_CLI_ID = CL.ID
                         AND CT.CTT_CTT_ID IS NULL
                         AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1
                         AND (CT.CTT_SEG_ID = idSeguro  OR idSeguro IS NULL)
                         AND CT.CTT_NUMAPOLICE IS NOT NULL) AS PREMIO
                   
                  FROM VER_CLIENTE CL
                  WHERE CL.ID IN (SELECT CT.CTT_CLI_ID
                                   FROM T_CONTRATO CT
                                   WHERE CT.CTT_SEG_ID = idSeguro
                                   AND CT.CTT_NUMAPOLICE IS NOT NULL
                                   AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1)
                  OR idSeguro IS NULL) 
        LOOP
          IF I.PREMIO IS NOT NULL THEN 
             valorTota := valorTota + I.PREMIO;
          END IF;
          
          I.PREMIO := PACK_LIB.MONEY(I.PREMIO)/*||' STD'*/;
          -- IF idSeguro IS NOT NULL THEN
          -- I.SEGURO := null;
          -- END IF;
    
           PIPE ROW(I);
        END LOOP;
        
        totalTypo."CLIENTE" := 'TOTAL';
        totalTypo."TOTAL PREMIO" := PACK_LIB.MONEY(valorTota)/*||' STD'*/;   
        PIPE ROW(totalTypo);      
      END;
  
  
      FUNCTION reportCrescentTime (dataInicio DATE, dataFim DATE,tipo NUMBER/* 1 - DIA | 2 - MES | 3 - ANO*/ )
      RETURN PACK_TYPE.filterReportCrescentTime PIPELINED
      IS
         format  VARCHAR(10);
         formatShow VARCHAR2(10);
         totalTime PACK_TYPE.reportTime;
      BEGIN
        CASE tipo
           WHEN 1 THEN
              format := 'YYYY-MM-DD';
              formatShow := 'DD-MM-YYYY';
           WHEN 2 THEN 
              format := 'YYYY-MM';
              formatShow := 'MON-YYYY';
           WHEN 3 THEN 
              format := 'YYYY';
              formatShow :=  'YYYY';
        END CASE;
        
        /*
        TYPE reportTime IS RECORD 
        -> "DATA" VARCHAR2(25),
        -> "NOVOS CLIENTES" NUMBER,
        -> "TOTAL CLIETES" NUMBER,
        -> "NOVOS CONTRATOS" NUMBER,
        -> "TOTAL CONTRATOS" NUMBER,
        -> "PREMIO" VARCHAR2(120),
        -> "TOTAL" VARCHAR2(120),
        -> "SEGURO EPOCA" VARCHAR2(100));
        */
        
        -- Não faz sentido adicoar o tatal nessa view
        totalTime."DATA" := 'Total';
        
        FOR I IN (SELECT
                      --DIST."DT" AS "ORG DATA",
                     TO_CHAR(TO_DATE(DIST."DT", format), formatShow) AS "DATA",
                    (SELECT COUNT(*) 
                        FROM T_CLIENTE CT
                        WHERE TO_CHAR(CT.CLI_DTREG, format) = DIST."DT") AS "NOVOS CLIENTES",
                        
                    (SELECT COUNT(*)
                        FROM T_CLIENTE CT
                        WHERE TO_CHAR(CT.CLI_DTREG, format) <= DIST."DT") AS "TODOS CLIENTES",
                        
                    (SELECT COUNT(*)
                        FROM T_CONTRATO CT
                        WHERE TO_CHAR(CT.CTT_DTCONTRATO, format) = DIST."DT" 
                           AND CT.CTT_CTT_ID IS NULL
                           AND CT.CTT_NUMAPOLICE IS NOT NULL) AS "NOVOS CONTRATOS",
                        
                    (SELECT COUNT(*)
                        FROM T_CONTRATO CT
                        WHERE TO_CHAR(CT.CTT_DTCONTRATO, format) <= DIST."DT"
                           AND CT.CTT_CTT_ID IS NULL
                           AND CT.CTT_NUMAPOLICE IS NOT NULL) AS "TODOS CONTRATOS",
                        
                  (SELECT CAST(SUM(CT.CTT_VPAGAR * TAX.TX_VENDA) AS VARCHAR2(120))
                       FROM T_CONTRATO CT 
                          INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CT.CTT_DTREG, CT.CTT_MOE_ID)) TAX ON 1 = 1
                       WHERE TO_CHAR(CT.CTT_DTCONTRATO, format) = DIST."DT" 
                          AND  CT.CTT_CTT_ID IS NULL) AS "PREMIO",
                  
                  (SELECT CAST(SUM(CT.CTT_VPAGAR * TAX.TX_VENDA) AS VARCHAR2(120))
                       FROM T_CONTRATO CT 
                          INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CT.CTT_DTREG, CT.CTT_MOE_ID)) TAX ON 1 = 1
                       WHERE TO_CHAR(CT.CTT_DTCONTRATO, format) <= DIST."DT"
                          AND  CT.CTT_CTT_ID IS NULL) AS "TOTAL",
                    
                      -- Buscar pelo seguro mais frequente antes da epoca
                    (SELECT SEG.SEG_NOME||' ('||SEG.TOTAL||')'
                          FROM(SELECT SE.SEG_NOME,
                                      TO_CHAR(CT.CTT_DTCONTRATO, format) AS "DDTATA",
                                      COUNT(*) AS "TOTAL"
                                  FROM T_CONTRATO CT
                                      INNER JOIN T_SEGURO SE  ON CT.CTT_SEG_ID = SE.SEG_ID
                                  WHERE CT.CTT_NUMAPOLICE IS NOT NULL
                                     AND  CT.CTT_CTT_ID IS NULL
                                  GROUP BY SE.SEG_NOME, TO_CHAR(CT.CTT_DTCONTRATO, format)
                                  ORDER  BY TOTAL DESC) SEG
                          WHERE  ROWNUM <=1 
                             AND SEG.DDTATA =  DIST."DT" 
                          ) AS "EPOCA"
                          
                 FROM ((SELECT
                            DISTINCT TO_CHAR(DIST.CTT_DTCONTRATO, format) AS "DT"
                         FROM T_CONTRATO DIST
                            UNION(SELECT TO_CHAR(CDIST.CLI_DTREG, format) AS "DT"
                                  FROM T_CLIENTE CDIST))
                         ) DIST
                WHERE 1 = PACK_LIB.BETWEENDATE(TO_DATE(DIST."DT", format), TO_DATE(TO_CHAR(dataInicio, format), format), TO_DATE(TO_CHAR(dataFim, format), format))                 
                 ORDER BY TO_DATE("DT", format) DESC)
        LOOP
           IF I.EPOCA IS NULL THEN I.EPOCA := 'Sem registros'; END IF;
           PIPE ROW(i);
        END LOOP;
    END;
    
    
    
    FUNCTION reportproducao( dataInicio DATE,dataFim DATE )
    RETURN PACK_TYPE.filterReportproducao PIPELINED
    IS
       
       TYPE ListKey IS TABLE OF VARCHAR2(1000) INDEX BY VARCHAR2(1000) ;
       TYPE HasMap IS TABLE OF PACK_TYPE.reportproducao INDEX BY VARCHAR2(1000);
       
       currentReport PACK_TYPE.reportproducao;
       
       keysIndex ListKey;
       mapValues HasMap ;
       
       totalProducao PACK_TYPE.reportproducao;
       sigla CHARACTER VARYING(1000);
    BEGIN
        -- TYPE reportproducao IS RECORD ("DATA" VARCHAR(25),"NUM APLOCIE" VARCHAR(30),CLIENTE VARCHAR(120),
        --"SEGURO" VARCHAR(70),"MOEDA" VARCHAR2(3),"PREMIO" VARCHAR(120) );
         
        totalProducao."DATA" := 'TOTAL';
        FOR I IN ( SELECT 
                        pack_lib.asddmmyyyy(CT.CTT_DTCONTRATO)AS "DATA",
                        CT.CTT_NUMAPOLICE AS "NUM APOLICE",
                        CT.CTT_EXTERNALCOD AS "NUM DEBITO",
                        CL.CLI_NOME||' '||CL.CLI_APELIDO  AS CLIENTE,
                        S.SEG_NOME AS SEGURO,
                        MO.MOE_SIGLA  AS MOEDA,
                        CAST ((CT.CTT_PBRUTO * TAX.TX_VENDA) AS VARCHAR2(120))AS PREMIO,
                        CAST ((CT.CTT_PBRUTO * TAX.TX_VENDA) * (ICONSUMO.IMPTAX_PERCENTAGEM/100) AS VARCHAR2(120)) AS  "IMPOSTO CONSUMO",
                        CAST ((CT.CTT_PBRUTO * TAX.TX_VENDA) * (ISELO.IMPTAX_PERCENTAGEM/100) AS VARCHAR2(120)) AS "IMPOSTO SELO",
                        CAST ((CT.CTT_PBRUTO * TAX.TX_VENDA) * (IFGA.IMPTAX_PERCENTAGEM/100) AS VARCHAR2(120)) AS "FGA",
                        CAST ((ct.ctt_vpagar * TAX.TX_VENDA) AS VARCHAR2 (120)) as "VALOR TOTAL"
                                    
                    FROM T_CONTRATO CT 
                      INNER JOIN T_CLIENTE CL ON CT.CTT_CLI_ID = CL.CLI_ID
                      INNER JOIN T_SEGURO S ON CT.CTT_SEG_ID = S.SEG_ID
                      INNER JOIN T_IMPOSTOTAXA ISELO ON CT.CTT_IMPTAX_SELO = ISELO.IMPTAX_ID
                      INNER JOIN T_IMPOSTOTAXA ICONSUMO ON CT.CTT_IMPTAX_CONSUMO = ICONSUMO.IMPTAX_ID
                      LEFT JOIN T_IMPOSTOTAXA IFGA ON CT.CTT_IMPTAX_FGA = IFGA.IMPTAX_ID
                      INNER JOIN T_MOEDA MO ON CT.CTT_MOE_ID = MO.MOE_ID 
                      INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CT.CTT_DTREG, CT.CTT_MOE_ID)) TAX ON 1 = 1
                    WHERE CT.CTT_SEG_ID != 3
                       AND  CT.CTT_CTT_ID IS NULL 
                       AND (( CT.CTT_DTCONTRATO BETWEEN DATAINICIO AND DATAFIM
                       OR (DATAINICIO IS NULL AND DATAFIM IS NULL))
                       AND CT.CTT_NUMAPOLICE IS NOT NULL)
                    ORDER BY CT.CTT_DTCONTRATO DESC)
        LOOP
        
        /*
        TYPE reportproducao IS RECORD 
        -> "DATA" VARCHAR(25),
        -> "NUM APOLICE" VARCHAR(30),
        -> CLIENTE VARCHAR(120),
        -> "SEGURO" VARCHAR(70),
        -> "MOEDA" VARCHAR2(3),
        -> "PREMIO" VARCHAR(120),
        -> "IMPOSTO CONSUMO"varchar2(120),
        -> "IMPOSTO SELO" varchar2(120),
        -> "FGA" VARCHAR2(120),
        -> "VALOR TOTAL"varchar2(120));
        */
           IF NOT keysIndex.EXISTS(I."SEGURO") THEN
              keysIndex(I."SEGURO") := I."SEGURO";
              currentReport."DATA" := 'TOTAL';
              currentReport."NUM APOLICE" := I."SEGURO";
              currentReport."PREMIO" := 0;
              currentReport."IMPOSTO CONSUMO" := 0;
              currentReport."IMPOSTO SELO" := 0;
              currentReport."FGA" := 0;
              currentReport."VALOR TOTAL" := 0;
              mapVAlues(I."SEGURO") := currentReport;
           END IF;
        
           IF NOT keysIndex.EXISTS('TOTAL') THEN
              keysIndex(I."MOEDA") :='TOTAL';
              currentReport."DATA" := 'TOTAL';
              currentReport."NUM APOLICE" := 'TOTAL';
              currentReport."PREMIO" := 0;
              currentReport."IMPOSTO CONSUMO" := 0;
              currentReport."IMPOSTO SELO" := 0;
              currentReport."FGA" := 0;
              currentReport."VALOR TOTAL" := 0;
              mapValues('TOTAL') := currentReport;
           END IF;
           
           
           
           currentReport := mapValues('TOTAL');
           currentReport."PREMIO" := currentReport."PREMIO" + I."PREMIO";
           currentReport."IMPOSTO CONSUMO" := currentReport."IMPOSTO CONSUMO" + I."IMPOSTO CONSUMO";
           currentReport."IMPOSTO SELO" := currentReport."IMPOSTO SELO" + I."IMPOSTO SELO";
           currentReport."FGA" := currentReport."FGA" + I."FGA";
           currentReport."VALOR TOTAL" := currentReport."VALOR TOTAL" + I."VALOR TOTAL";
           mapValues('TOTAL') := currentReport;
           
           currentReport := mapValues(I."SEGURO");
           
           currentReport."PREMIO" := currentReport."PREMIO" + I."PREMIO";
           currentReport."IMPOSTO CONSUMO" := currentReport."IMPOSTO CONSUMO" + I."IMPOSTO CONSUMO";
           currentReport."IMPOSTO SELO" := currentReport."IMPOSTO SELO" + I."IMPOSTO SELO";
           currentReport."FGA" := currentReport."FGA" + I."FGA";
           currentReport."VALOR TOTAL" := currentReport."VALOR TOTAL" + I."VALOR TOTAL";
           
           mapValues(I.SEGURO) := currentReport;
           
           
           
           I."PREMIO" := PACK_LIB.MONEY(I."PREMIO")/*||' STD'*/;
           I."IMPOSTO CONSUMO" := PACK_LIB.MONEY(I."IMPOSTO CONSUMO")/*||' STD'*/;
           I."IMPOSTO SELO" := PACK_LIB.MONEY(I."IMPOSTO SELO")/*||' STD'*/;
           I."VALOR TOTAL" := PACK_LIB.MONEY(I."VALOR TOTAL")/*||' STD'*/;
           I."FGA" := PACK_LIB.MONEY(I."FGA")/*||' STD'*/;
           
           PIPE ROW(I);
        END LOOP;
        
        sigla  := mapValues.FIRST;
        
        WHILE sigla IS NOT NULL LOOP
        
           currentReport := mapValues(sigla);
           IF sigla = 'TOTAL' THEN
              sigla := mapValues.NEXT(sigla);
              CONTINUE; 
          END IF;
           
           currentReport."PREMIO" := PACK_LIB.MONEY(currentReport."PREMIO")/*||' STD'*/;
           currentReport."IMPOSTO CONSUMO" := PACK_LIB.MONEY(currentReport."IMPOSTO CONSUMO")/*||' STD'*/;
           currentReport."IMPOSTO SELO" := PACK_LIB.MONEY(currentReport."IMPOSTO SELO")/*||' STD'*/;
           currentReport."FGA" := PACK_LIB.MONEY(currentReport."FGA")/*||' STD'*/;
           currentReport."VALOR TOTAL" := PACK_LIB.MONEY(currentReport."VALOR TOTAL")/*||' STD'*/;
           sigla := mapValues.NEXT(sigla);
           PIPE ROW(currentReport);
           
        END LOOP;
        
        currentReport := mapValues('TOTAL');
        currentReport."PREMIO" := PACK_LIB.MONEY(currentReport."PREMIO")/*||' STD'*/;
        currentReport."IMPOSTO CONSUMO" := PACK_LIB.MONEY(currentReport."IMPOSTO CONSUMO")/*||' STD'*/;
        currentReport."IMPOSTO SELO" := PACK_LIB.MONEY(currentReport."IMPOSTO SELO")/*||' STD'*/;
        currentReport."FGA" := PACK_LIB.MONEY(currentReport."FGA")/*||' STD'*/;
        currentReport."VALOR TOTAL" := PACK_LIB.MONEY(currentReport."VALOR TOTAL")/*||' STD'*/;
        sigla := mapValues.NEXT(sigla);
        PIPE ROW(currentReport);
    END;
    
    
    FUNCTION REPORTSEGURO (dataInicio DATE,dataFim DATE ) RETURN PACK_TYPE.filterReportSeguro PIPELINED
    IS
      rowL PACK_TYPE.reportClient;
      totalpremio PACK_TYPE.ReportSeguro;
      valortotalpremio float:= 0;
      uheru number;
     /*
        reportSeguro IS RECORD -> 
           SEGURO VARCHAR2(100), 
           CLIENTES VARCHAR2(10), 
           "CLIENTE FREQ." VARCHAR, 
           "PREMIO" VARCHAR2(120))
     */
    BEGIN
      FOR I IN (SELECT
                   CL.SEG_NOME,
                  (SELECT COUNT(*)
                      FROM T_CONTRATO CT
                      WHERE CT.CTT_SEG_ID = CL.SEG_ID
                      AND CT.CTT_NUMAPOLICE IS NOT NULL) AS CLIENTES,
                      
                  (SELECT FREQ.CLI_NOME||' ('||FREQ.TOTAL||')'
                      FROM(SELECT CT.CTT_SEG_ID,
                                  CLL.CLI_NOME,
                                  COUNT(*) AS TOTAL
                              FROM T_CLIENTE CLL
                                 INNER JOIN T_CONTRATO CT ON CLL.CLI_ID = CT.CTT_CLI_ID
                              WHERE PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1
                                 AND CT.CTT_NUMAPOLICE IS NOT NULL
                                 AND CT.CTT_CTT_ID IS NULL
                              GROUP BY  CT.CTT_SEG_ID, CLL.CLI_NOME
                              ORDER  BY TOTAL DESC) FREQ
                      WHERE FREQ.CTT_SEG_ID = CL.SEG_ID
                         AND ROWNUM <=1
                      ) AS SEGURO,
                      
                  (SELECT cast(SUM(CT.CTT_VPAGAR * TAX.TX_VENDA) as VARCHAR(120))
                      FROM T_CONTRATO CT
                         INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CT.CTT_DTREG, CT.CTT_MOE_ID)) TAX ON 1 = 1
                      WHERE CT.CTT_SEG_ID = CL.SEG_ID
                         AND  CT.CTT_CTT_ID IS NULL
                         AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1) AS PREMIO
                         
                  FROM T_SEGURO CL) 
      LOOP
      IF I.PREMIO IS NOT NULL THEN 
         valortotalpremio:=  valortotalpremio + I.PREMIO;
          END IF;
          I.PREMIO := PACK_LIB.MONEY(I.PREMIO)/*||' STD'*/;
      PIPE ROW(I);
      END LOOP;
      
      totalpremio."SEGURO" := 'TOTAL';
      totalpremio."PREMIO" := PACK_LIB.MONEY(valortotalpremio)/*||' STD'*/;   
      PIPE ROW(totalpremio);
        
      
  END;
  
  
  
  
  
  
    FUNCTION repostStatusCliente(idCliente NUMBER,dataInicio DATE,dataFim date)
    RETURN PACK_TYPE.filterReportStatuClient PIPELINED
    IS
       totalReport PACK_TYPE.reportClient;
       total FLOAT := 0;
       
    BEGIN
        --  (SEGURO VARCHAR, "PRIMEIRO CONTRATO" VARCHAR2(10), "QUANTIDADE" NUMBER, "PREMIO" VARCHAR2(120));
        FOR I IN (SELECT
                       CL.SEG_NOME,
                       (SELECT TO_CHAR(MIN(CT.CTT_DTCONTRATO), 'DD-MM-YYYY')
                            FROM T_CONTRATO CT 
                            WHERE CT.CTT_CLI_ID = idCliente
                               AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1
                               AND CT.CTT_NUMAPOLICE IS NOT NULL
                               AND CT.CTT_CTT_ID IS NULL
                               AND CT.CTT_SEG_ID = CL.SEG_ID) AS FRIST,
                               
                       (SELECT COUNT(*) 
                           FROM T_CONTRATO CT 
                           WHERE CT.CTT_CLI_ID = idCliente
                              AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1
                              AND CT.CTT_NUMAPOLICE IS NOT NULL
                              AND CT.CTT_SEG_ID = CL.SEG_ID) "QUANT",
                              
                       (SELECT CAST(SUM(CT.CTT_VPAGAR) * TAX.TX_VENDA AS VARCHAR2(120))
                           FROM T_CONTRATO CT
                              INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CT.CTT_DTREG, CT.CTT_MOE_ID)) TAX ON 1 = 1
                           WHERE CT.CTT_CLI_ID = idCliente
                              AND PACK_LIB.BETWEENDATE(CT.CTT_DTCONTRATO, dataInicio, dataFim) = 1
                              AND CT.CTT_NUMAPOLICE IS NOT NULL
                              AND  CT.CTT_CTT_ID IS NULL
                              AND CT.CTT_SEG_ID = CL.SEG_ID) AS "PREMIO"
                      
                      FROM T_SEGURO CL) 
          LOOP
              IF I."QUANT" != 0 THEN
                 PIPE ROW(I);
                 IF I."PREMIO" IS NOT NULL THEN
                    total := total + I."PREMIO";
                 END IF;
              END IF;
          END LOOP;
          
          totalReport."PREMIO" := PACK_LIB.MONEY(total)/*||' STD'*/;
          totalReport."SEGURO" := 'Total';
          PIPE ROW(totalReport);
    END;   
    
    
    
    FUNCTION  reportproducaotipo(dataInicio DATE,dataFim DATE,ID NUMBER, idSeguro NUMBER 
    )RETURN PACK_TYPE.filterReportProducao PIPELINED
  
  IS
     sumPremio FLOAT := 0;
     sumConsumo FLOAT := 0;
     sumSelo FLOAT := 0;
     sumTotal FLOAT := 0;
     sumFGA FLOAT :=0;
     lastRow PACK_TYPE.reportproducao;
  BEGIN
  /*
   TYPE reportproducao IS RECORD ("DATA" VARCHAR(25),"NUM APOLICE" VARCHAR(30),CLIENTE VARCHAR(120),"SEGURO" VARCHAR(70),"MOEDA" VARCHAR2(3),"PREMIO" VARCHAR(120),"IMPOSTO CONSUMO"varchar2(120),"IMPOSTO SELO" varchar2(120),"VALOR TOTAL"varchar2(120));
    TYPE filterReportproducao IS TABLE OF reportproducao;
    
  */
     -- SEGURO 3 -> SEGURO DE VIAGEM
     FOR I IN ( SELECT 
                    pack_lib.asddmmyyyy(CT.CTT_DTCONTRATO)AS "DATA",
                    CT.CTT_NUMAPOLICE AS "NUM APOLICE",
                    CT.CTT_EXTERNALCOD AS "NUM DEBITO",
                    CL.CLI_NOME||' '||CL.CLI_APELIDO  AS CLIENTE,
                    S.SEG_NOME AS SEGURO,
                    MO.MOE_SIGLA  AS MOEDA,
                    
                    CASE 
                       WHEN CT.CTT_SEG_ID = 3 THEN CAST(CT.CTT_PBRUTO AS VARCHAR2(120))
                       ELSE CAST((CT.CTT_PBRUTO * TAX.TX_VENDA) AS VARCHAR2(120))
                    END AS PREMIO,
                    
                    CASE
                       WHEN CT.CTT_SEG_ID = 3 THEN CAST((CT.CTT_PBRUTO * (ICONSUMO.IMPTAX_PERCENTAGEM/100)) AS VARCHAR2(120))
                       ELSE CAST(((CT.CTT_PBRUTO * (ICONSUMO.IMPTAX_PERCENTAGEM/100))* TAX.TX_VENDA) AS VARCHAR2(120)) 
                    END AS  "IMPOSTO CONSUMO",
                    
                    CASE 
                       WHEN CT.CTT_SEG_ID = 3 THEN CAST((CT.CTT_PBRUTO * (ISELO.IMPTAX_PERCENTAGEM/100)) AS VARCHAR2(120))
                       ELSE CAST(((CT.CTT_PBRUTO * (ISELO.IMPTAX_PERCENTAGEM/100)) * TAX.TX_VENDA) AS VARCHAR2(120))
                    END AS "IMPOSTO SELO",
                    
                    CASE 
                       WHEN CT.CTT_SEG_ID = 3 THEN CAST((CT.CTT_PBRUTO * (IFGA.IMPTAX_PERCENTAGEM/100)) AS VARCHAR2(120)) 
                       ELSE CAST(((CT.CTT_PBRUTO * (IFGA.IMPTAX_PERCENTAGEM/100)) * TAX.TX_VENDA) AS VARCHAR2(120))
                    END AS "FGA",
                    
                    CASE 
                       WHEN CT.CTT_SEG_ID = 3 THEN CAST(ct.ctt_vpagar AS VARCHAR2(120))
                       ELSE CAST(ct.ctt_vpagar * TAX.TX_VENDA AS VARCHAR2(120))
                    END as "TOTAL"
                                
                FROM T_CONTRATO CT 
                  INNER JOIN T_CLIENTE CL ON CT.CTT_CLI_ID = CL.CLI_ID
                  INNER JOIN T_SEGURO S ON CT.CTT_SEG_ID = S.SEG_ID
                  INNER JOIN T_IMPOSTOTAXA ISELO ON CT.CTT_IMPTAX_SELO = ISELO.IMPTAX_ID
                  INNER JOIN T_IMPOSTOTAXA ICONSUMO ON CT.CTT_IMPTAX_CONSUMO = ICONSUMO.IMPTAX_ID
                  LEFT JOIN T_IMPOSTOTAXA IFGA ON CT.CTT_IMPTAX_FGA = IFGA.IMPTAX_ID
                  INNER JOIN T_MOEDA MO ON CT.CTT_MOE_ID = MO.MOE_ID
                  INNER JOIN T_TAXA TAX ON PACK_REGRAS.GET_TAXA_DIA(CT.CTT_DTREG, CT.CTT_MOE_ID) = TAX.TX_ID
                WHERE --CT.CTT_SEG_ID  != 3
                  -- AND 
                  CT.CTT_CTT_ID IS NULL
                  AND (CT.CTT_DTCONTRATO BETWEEN DATAINICIO AND DATAFIM 
                  OR (DATAINICIO IS NULL AND DATAFIM IS NULL)) AND
                 ( (CL.CLI_ID =ID AND idSeguro = 1) OR S.SEG_ID = ID AND idSeguro = 2)
                ORDER BY CT.CTT_DTCONTRATO DESC)      
                  

    LOOP
        sumPremio := sumPremio + TO_NUMBER(I.PREMIO);
        sumConsumo := sumConsumo + TO_NUMBER(I."IMPOSTO CONSUMO");
        sumSelo := sumSelo + TO_NUMBER(I."IMPOSTO SELO");
        sumTotal := sumTotal + TO_NUMBER(I."TOTAL");
        IF I."FGA" IS NOT NULL THEN sumFGA := sumFGA + TO_NUMBER(I."FGA"); END IF;
        
        I.PREMIO := PACK_LIB.MONEY(I.PREMIO);
        I."IMPOSTO CONSUMO" := PACK_LIB.MONEY(I."IMPOSTO CONSUMO");
        I."IMPOSTO SELO" := PACK_LIB.MONEY(I."IMPOSTO SELO");
        I."TOTAL" := PACK_LIB.MONEY(I."TOTAL");
        I."FGA" := PACK_LIB.MONEY(I."FGA");
        PIPE ROW(I);
      END LOOP;
      
      -- "PREMIO" VARCHAR(120),"IMPOSTO CONSUMO"varchar2(120),"IMPOSTO SELO" varchar2(120),"VALOR TOTAL"varchar2(120));
      lastRow."DATA" := 'SOMATORIO';
      lastRow."PREMIO" := PACK_LIB.MONEY(sumPremio);
      lastRow."IMPOSTO CONSUMO" := PACK_LIB.MONEY(sumConsumo);
      lastRow."IMPOSTO SELO" := PACK_LIB.MONEY(sumSelo);
      lastRow."VALOR TOTAL":=PACK_LIB.MONEY(sumTotal);
      lastRow."FGA" := PACK_LIB.MONEY(sumFGA);
      PIPE ROW(lastRow);
   END;
      
   FUNCTION reportCresentSeguro
    (
       dataInicio DATE,
       dataFim DATE,
       typeDate NUMBER,
       idSeguro NUMBER
    )RETURN PACK_TYPE.filtereportCresentSeguro PIPELINED         
     
      IS
         format VARCHAR2(10) := 'YYYY-MM-DD';
         formatShow VARCHAR2(10) := 'DD-MM-YYYY';
         totalReport PACK_TYPE.reportCresentSeguro;
      BEGIN
         IF typeDate = 2 THEN
            format := 'YYYY-MM';
            formatShow := 'MON-YYYY';
         ELSIF typeDate = 3 THEN
            format := 'YYYY';
            formatShow := 'YYYY';
         END IF;
         
          --TYPE reportCresentSeguro IS RECORD
          --("DATA" VARCHAR2(25),
          --"NOVOS ADERENTE" NUMBER,
          --"TODOS ADERENTES" NUMBER, 
          
          --"NOVOS CONTRATOS" NUMBER, 
          --"TODOS CONTRATOS" NUMBER,
          --"PREMIO EPOCA" VARCHAR(120),
          --"PREMIO" VARCHAR(120)); 
    
          --TYPE filtereportCresentSeguro IS TABLE OF reportCresentSeguro;
 
  FOR I IN (SELECT 
                TO_CHAR(TO_DATE(DIST."HOJE", format), formatShow) as "DATA",
                  (select count (DISTINCT CT.CTT_CLI_ID)
                          FROM T_CONTRATO CT
                          WHERE CT.CTT_SEG_ID = IDSEGURO 
                             AND  CT.CTT_CTT_ID IS NULL
                             AND TO_CHAR(CT.CTT_DTCONTRATO, FORMAT)= DIST."HOJE" 
                             AND  CT.CTT_CLI_ID NOT IN (SELECT  CT.CTT_CLI_ID
                                                              FROM T_CONTRATO CT
                                                              WHERE CT.CTT_SEG_ID = IDSEGURO 
                                                                 AND  CT.CTT_CTT_ID IS NULL
                                                                 AND TO_CHAR(CT.CTT_DTCONTRATO,format) <  DIST."HOJE")) AS NOVO,
                        (select count (DISTINCT CT.CTT_CLI_ID)
                          FROM T_CONTRATO CT
                          WHERE CT.CTT_SEG_ID = IDSEGURO
                             AND CT.CTT_CTT_ID IS NULL
                             AND TO_CHAR(CT.CTT_DTCONTRATO, FORMAT)<= DIST."HOJE") AS "TOTAL",
                          
                          
                          (SELECT COUNT(*)
                                    FROM T_CONTRATO CT
                                    WHERE CT.CTT_SEG_ID = IDSEGURO
                                       AND  CT.CTT_CTT_ID IS NULL
                                       AND TO_CHAR(CT.CTT_DTCONTRATO, format) = DIST."HOJE") AS "NOVOS contratos",
                                     
                        (SELECT COUNT(*)
                            FROM T_CONTRATO CT
                            WHERE CT.CTT_SEG_ID = IDSEGURO
                               AND  CT.CTT_CTT_ID IS NULL
                               AND TO_CHAR(CT.CTT_DTCONTRATO, format) <= DIST."HOJE" ) AS "TODOS CONTRATOS",
                      
                        (select CAST (SUM (CT.CTT_VPAGAR * TAX.TX_VENDA) AS VARCHAR2(120))/*||' STD'*/
                                FROM T_CONTRATO CT
                                   INNER JOIN T_TAXA TAX ON PACK_REGRAS.GET_TAXA_DIA(CT.CTT_DTREG, CT.CTT_MOE_ID) = TAX.TX_ID
                                WHERE CT.CTT_SEG_ID = IDSEGURO
                                   AND  CT.CTT_CTT_ID IS NULL
                                   AND TO_CHAR(CT.CTT_DTCONTRATO, FORMAT)= DIST."HOJE") AS "PREMIO EPOCAS ",
                          
                           
                        (select CAST(SUM (CT.CTT_VPAGAR * TAX.TX_VENDA) AS VARCHAR2(120))/*||' STD'*/
                                FROM T_CONTRATO CT
                                   INNER JOIN T_TAXA TAX ON PACK_REGRAS.GET_TAXA_DIA(CT.CTT_DTREG, CT.CTT_MOE_ID) = TAX.TX_ID
                                WHERE CT.CTT_SEG_ID <= IDSEGURO
                                   AND CT.CTT_CTT_ID IS NULL
                                   AND TO_CHAR(CT.CTT_DTCONTRATO, FORMAT)<= DIST."HOJE") AS "VALOR TOTAL "
                  
              FROM ((SELECT
                        DISTINCT TO_CHAR(DIST.CTT_DTCONTRATO, format) AS "HOJE"
                     FROM T_CONTRATO DIST)
                     )DIST
              ORDER BY TO_DATE("HOJE", format) DESC)
               
                  
      LOOP
        PIPE ROW (I );
      END LOOP;
    END; 

   FUNCTION reportSegurosCompras (dataInicio DATE, dataFim DATE) RETURN PACK_TYPE.filterSeguros PIPELINED
   IS
   BEGIN
      FOR I IN (SELECT DISTINCT VV.*
                  FROM T_CONTRATO CT 
                     INNER JOIN VER_SEGURO VV ON CT.CTT_SEG_ID = VV.ID
                  WHERE CT.CTT_DTCONTRATO BETWEEN dataInicio AND dataFim
                      OR dataInicio IS NULL AND dataFim IS NULL)
      LOOP
         PIPE ROW(I);
      END LOOP;
   END;
   
   
   FUNCTION reportTaxas (nomeMoeda VARCHAR2) RETURN PACK_TYPE.filterTaxas PIPELINED
   IS
      mediaReport PACK_TYPE.taxas;
      taxa PACK_TYPE.taxas;
      totalCompras FLOAT := 0;
      totalVendas FLOAT := 0;
      total NUMBER := 0;
   BEGIN
      FOR I IN (SELECT DISTINCT * 
                   FROM (SELECT
                             BASE.MOE_NOME AS "BASE", 
                             PACK_LIB.MONEY(T.TX_COMPRA)||' '||MD.MOE_NOME AS "COMPRA",
                             PACK_LIB.MONEY(T.TX_VENDA)||' '||MD.MOE_NOME AS "VENDA",
                             TO_CHAR(T.TX_DTREG, 'YYYY-MM-DD') AS REGISTRO,
                             CASE WHEN T.TX_STATE = 1 THEN 'Ativo'
                                  ELSE 'Fechada'
                             END AS "ESTADO"
                        FROM T_TAXA T
                           INNER JOIN T_MOEDA MD ON T.TX_MOE_ID = MD.MOE_ID
                           INNER JOIN T_MOEDA BASE ON T.TX_MOE_BASE = BASE.MOE_ID
                        WHERE  BASE.MOE_NOME = nomeMoeda) TAXA
                        ORDER BY TAXA.BASE ASC,
                           TAXA.ESTADO ASC)
      LOOP       
           /*
           TYPE taxas IS RECORD ->
           "MOEDA" VARCHAR2(50), 
           "VALOR COMPRA" VARCHAR2(120),  
           "VALOR VENDA" VARCHAR2(120), 
           "REGISTRO" VARCHAR2(20), 
           "ESTADO" VARCHAR2(20));
          
          IF I.COMPRA IS NOT NULL THEN totalCompras := totalCompras + I."COMPRA"; END IF;
          IF I."VENDA" IS NOT NULL THEN totalVendas := totalVendas + I."VENDA"; END IF;
          
          taxa."MOEDA" := I."BASE";
          taxa."VALOR COMPRA" := PACK_LIB.MONEY(I."COMPRA")||' '||I."MOEDA";
          taxa."VALOR VENDA" :=  PACK_LIB.MONEY(I."VENDA")||' '||I."MOEDA";
          taxa."REGISTRO" := I.REGISTRO;
          taxa."ESTADO" := I.ESTADO;*/
          
         
          -- total := total + 1;
          
          PIPE ROW(I);
      END LOOP;
      
      /*mediaReport."VALOR COMPRA" := PACK_LIB.MONEY(totalCompras/total)||' STD';
      mediaReport."VALOR VENDA" := PACK_LIB.MONEY(totalVendas/total)||' STD';
      */
     --  PIPE ROW(mediaReport);
   END;
   
   
   FUNCTION reportRecebimento (dataInicio DATE, dataFim DATE) RETURN PACK_TYPE.filterRecebimento PIPELINED
   IS
      totalRecebimento PACK_TYPE.reportRecebimento;
      total FLOAT := 0;
   BEGIN
      -- TYPE reportRecebimento IS RECORD("DATA" NUMBER, "CODIGO" VARCHAR2(30), "RECIBO" VARCHAR2(20), "FORMA PAGAMENTO" VARCHAR2(50),
      -- "BANCO" VARCHAR2(20), "BENEFICIARIO" VARCHAR2(120), "DESCRICAO" VARCHAR2(100), "VALOR" VARCHAR2(120));
   

      FOR I IN (SELECT TO_CHAR(AM.AMORT_DTREG, 'DD-MM-YYYY') AS "DATA",
                       '20000' AS "CODIGO",
                       'R/N '||AM.AMORT_ID AS "RECIBO",
                       FORMA_PAY.OBJT_DESC AS "FORMA PAY",
                       BK.BK_SIGLA||' '||MD.MOE_SIGLA||' '||TCONTA.OBJT_DESC AS "CONTA",
                       CL.CLI_NOME ||' '||CL.CLI_APELIDO AS "CLIENTE",
                       'SENDO O PREMIO SOBRE APOLICE '||CT.CTT_NUMAPOLICE AS "DESCRISAO",
                       CAST(AM.AMORT_VALOR * TAX.TX_VENDA AS VARCHAR2(120)) AS "VALOR"
                   FROM T_PRESTACAO PR
                      INNER JOIN T_AMORTIZACAO AM ON PR.PREST_ID = AM.AMORT_PREST_ID
                      INNER JOIN T_ACCOUNT AC  ON AC.COUNT_ID = AM.AMORT_ACCOUNT_ID
                      INNER JOIN T_BANK BK ON AC.COUNT_BK_ID = BK.BK_ID
                      INNER JOIN T_OBJECTYPE TCONTA ON AC.COUNT_OBJT_SUBTPCOUNT = TCONTA.OBJT_ID
                      INNER JOIN T_MOEDA MD ON AC.COUNT_MOE_ID =MD.MOE_ID
                      INNER JOIN T_OBJECTYPE FORMA_PAY ON AM.AMORT_OBJT_ID = FORMA_PAY.OBJT_ID
                      INNER JOIN T_CONTRATO CT ON PR.PREST_CTT_ID = CT.CTT_ID
                      INNER JOIN T_CLIENTE CL ON CT.CTT_CLI_ID  = CL.CLI_ID
                      INNER JOIN T_SEGURO SE ON CT.CTT_SEG_ID = SE.SEG_ID
                      INNER JOIN T_TAXA TAX ON PACK_REGRAS.GET_TAXA_DIA(CT.CTT_DTREG, AC.COUNT_MOE_ID) = TAX.TX_ID
                   WHERE  CT.CTT_CTT_ID IS NULL 
                      AND 1 = (CASE
                                 WHEN dataInicio IS NOT NULL AND dataFim IS NOT NULL AND AM.AMORT_DTREG BETWEEN dataInicio AND dataFim THEN 1
                                 WHEN dataInicio IS NOT NULL AND TO_CHAR(dataInicio, 'YYYY-MM-DD') = TO_CHAR(AM.AMORT_DTREG, 'YYYY-MM-DD') THEN 1
                                 WHEN dataFim IS NOT NULL AND TO_CHAR(dataFim, 'YYYY-MM-DD') = TO_CHAR(AM.AMORT_DTREG, 'YYYY-MM-DD') THEN 1
                                 WHEN dataInicio IS NULL OR dataFim IS NULL THEN 1
                                 ELSE 0
                              END)
                  ORDER BY "CONTA" ASC, AM.AMORT_DTREG DESC)
      LOOP
         IF I."VALOR" IS NOT NULL THEN
            total := total + I.VALOR;
         END IF;
         
         I."VALOR" := PACK_LIB.MONEY(I."VALOR")/*||' STD'*/;
         PIPE ROW(I);
      END LOOP;
      
      totalRecebimento."DATA" := 'TOTAL';
      totalRecebimento."VALOR" := PACK_LIB.MONEY(total)/*||' STD'*/;
      PIPE ROW(totalRecebimento);
   END;
   
   
    FUNCTION reportPagamento(dataInicio DATE, dataFim DATE) RETURN PACK_TYPE.filterPayment PIPELINED
    IS
       total FLOAT := 0;
       totalPagamento PACK_TYPE.reportPayment;
       pagamento PACK_TYPE.reportPayment;
    BEGIN
        -- >TYPE reportPayment 
        -- "DATA" VARCHAR2(20), 
        -- "CODIGO" VARCHAR2(30),  
        -- "FORMA PAGAMENTO" VARCHAR2(50),
        -- "BANCO" VARCHAR2(50),
        -- "BENEFICIARIO" VARCHAR2(120),
        -- "DESCRICAO" VARCHAR2(150),
        -- "VALOR" VARCHAR2(120)
   
        FOR I IN (SELECT 
                       TO_CHAR(PAY.PAY_DTREG, 'DD-MM-YYYY') AS "DATA",
                       'P' AS "CODIGO",
                       CASE 
                          WHEN PAY_OBJ_FORMAPAYMENT = 2 
                             AND PAY.PAY_DOCMENTPAYMENT IS NOT NULL 
                             AND LENGTH (PAY.PAY_DOCMENTPAYMENT ) >= 10 THEN SUBSTR(PAY.PAY_DOCMENTPAYMENT, LENGTH(PAY.PAY_DOCMENTPAYMENT) - 10, LENGTH(PAY.PAY_DOCMENTPAYMENT))
                          WHEN PAY.PAY_DOCMENTPAYMENT IS NOT NULL THEN FORMA.OBJT_DESC || '.'||PAY.PAY_DOCMENTPAYMENT
                          ELSE FORMA.OBJT_DESC 
                       END AS "FORMA_PAY",
                       BK.BK_SIGLA||' '||MD.MOE_SIGLA||' '||TCONTA.OBJT_DESC AS "CONTA",
                       APAY.COUNT_NIB AS "PAGAMENTO",
                       ITP.IPAY_BENEFICIARIO AS "BENEFICIARIO",
                       ITP.IPAY_DESC AS "DESCRISAO",
                       CAST(ITP.IPAY_VALUE AS VARCHAR2(500)) AS "VALOR"
                     FROM T_PAYMENT PAY
                        INNER JOIN T_ACCOUNT AC ON PAY.PAY_ACCOUNT_ID = AC.COUNT_ID
                        INNER JOIN T_BANK BK ON AC.COUNT_BK_ID = BK.BK_ID
                        INNER JOIN T_OBJECTYPE TCONTA ON AC.COUNT_OBJT_SUBTPCOUNT = TCONTA.OBJT_ID
                        INNER JOIN T_MOEDA MD ON AC.COUNT_MOE_ID =MD.MOE_ID
                        INNER JOIN T_ITEMPAYMENT ITP ON PAY.PAY_ID = ITP.IPAY_PAY_ID
                        INNER JOIN T_OBJECTYPE FORMA ON PAY.PAY_OBJ_FORMAPAYMENT = FORMA.OBJT_ID 
                        INNER JOIN T_ACCOUNT APAY ON ITP.IPAY_ACCOUNT_ID = APAY.COUNT_ID
                    WHERE 1 = (CASE 
                                  WHEN dataInicio IS NOT NULL AND dataFim IS NOT NULL AND PAY.PAY_DTREG BETWEEN dataInicio AND dataFim THEN 1
                                  WHEN dataInicio IS NOT NULL AND TO_CHAR(dataInicio, 'YYYY-MM-DD') = TO_CHAR(PAY.PAY_DTREG, 'YYYY-MM-DD') THEN 1
                                  WHEN dataFim IS NOT NULL AND TO_CHAR(dataFim, 'YYYY-MM-DD') = TO_CHAR(PAY.PAY_DTREG, 'YYYY-MM-DD') THEN 1
                                  WHEN dataInicio IS NULL OR dataFim IS NULL THEN 1
                                  ELSE 0
                               END)
                    ORDER BY PAY.PAY_DTREG DESC)
        LOOP
           IF I."VALOR" IS NOT NULL THEN
              total := total + I."VALOR";
           END IF;
           
              I."VALOR" := PACK_LIB.MONEY(I."VALOR")/*||' STD'*/;
            
           /*
            TYPE reportPayment IS RECORD("DATA" VARCHAR2(20),
            "CODIGO" VARCHAR2(30),
            "FORMA PAGAMENTO" VARCHAR2(50),
            "BANCO" VARCHAR2(50),
            "PAGAMENTO" VARCHAR2(100),
            "BENEFICIARIO" VARCHAR2(120),
            "DESCRICAO" VARCHAR2(150),
            "VALOR" VARCHAR2(120));
             TYPE filterPayment IS TABLE OF reportPayment;
             */
             pagamento."DATA" := I."DATA";
             pagamento."CODIGO" := I."CODIGO";
             pagamento."FORMA PAGAMENTO" := I."FORMA_PAY";
             pagamento."BANCO" := I."CONTA";
             pagamento."BENEFICIARIO" := I."BENEFICIARIO";
             pagamento."DESCRICAO" := I."DESCRISAO";
             pagamento."VALOR" := I."VALOR";
             pagamento."PAGAMENTO" := I."PAGAMENTO";
           
           PIPE ROW(pagamento);
        END LOOP;
        totalPagamento."DATA" := 'TOTAL';
        totalPagamento."VALOR" := PACK_LIB.MONEY(total)/*||' STD'*/;
        PIPE ROW(totalPagamento);
    END;
    
    
    
    
    FUNCTION reportProducaoContaNotTravel (dateInicio DATE, dateFim DATE, idCaracteristica NUMBER) RETURN PACK_TYPE.filterProducaoConta PIPELINED
    IS
        TYPE ListChracter IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(100);
        TYPE MapProducoa IS TABLE OF PACK_TYPE.reportProducaoConta INDEX BY VARCHAR2(100);
        
        
        listSeguros ListChracter;
        mapSubTotal MapProducoa;
        
        totalSTD float := 0;
        totalUSD float := 0;
        totalEUR float := 0;
        reportRow PACK_TYPE.reportProducaoConta;
        currentSubTotal PACK_TYPE.reportProducaoConta;
        nomeSeguro CHARACTER VARYING(100);
    BEGIN
        FOR AM IN (SELECT
                   TO_CHAR(AM.AMORT_DTREG, 'DD-MM-YYYY') AS "DATA",
                   CLI.CLI_NOME||' '||CLI.CLI_APELIDO AS "CLIENTE",
                   SE.SEG_NOME AS "SEGURO",
                   CT.CTT_NUMAPOLICE AS "APOLICE",
                   SE.SEG_CODIGO||' '||AM.AMORT_ID AS "DEBITO",
                   BK.BK_SIGLA||' '||' '||MD.MOE_SIGLA||' '||TIPO_CONTA_BANCO.OBJT_DESC AS "BANCO",
                    CASE 
                       WHEN UPPER(MD.MOE_SIGLA) = 'STD' THEN CAST(AM.AMORT_VALOR AS VARCHAR2(120))
                       ELSE CAST((TAXA.TX_COMPRA * AM.AMORT_VALOR) AS VARCHAR2(120))
                   END AS "STD",
                    CASE 
                       WHEN UPPER(MD.MOE_SIGLA) = 'USD' THEN CAST(AM.AMORT_VALOR AS VARCHAR2(120))
                       ELSE '0'
                   END AS "USD",
                    CASE 
                       WHEN UPPER(MD.MOE_SIGLA) = 'EUR' THEN CAST(AM.AMORT_VALOR AS VARCHAR2(120))
                       ELSE '0'
                   END AS "EUR"
                   
                 FROM T_AMORTIZACAO AM
                     INNER JOIN T_PRESTACAO PR  ON AM.AMORT_PREST_ID = PR.PREST_ID
                     INNER JOIN T_CONTRATO CT ON PR.PREST_CTT_ID = CT.CTT_ID
                     INNER JOIN T_CLIENTE CLI ON CT.CTT_CLI_ID = CLI.CLI_ID
                     INNER JOIN T_SEGURO SE ON CT.CTT_SEG_ID = SE.SEG_ID
                     INNER JOIN T_ACCOUNT AC ON AM.AMORT_ACCOUNT_ID = AC.COUNT_ID
                     INNER JOIN T_BANK  BK ON AC.COUNT_BK_ID = BK.BK_ID
                     INNER JOIN T_MOEDA MD ON AC.COUNT_MOE_ID = MD.MOE_ID
                     INNER JOIN T_OBJECTYPE TIPO_CONTA_BANCO ON AC.COUNT_OBJT_SUBTPCOUNT = TIPO_CONTA_BANCO.OBJT_ID
                     INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(AM.AMORT_DTREG, MD.MOE_ID)) TAXA ON 1 = 1
                WHERE SE.SEG_CARACT_ID != 3
                    AND CT.CTT_CTT_ID IS NULL
                    AND 1 = (CASE 
                                WHEN dateInicio IS NOT NULL AND dateFim IS NOT NULL and  cast(am.amort_dtreg as date) between dateInicio and dateFim then 1
                                when dateInicio is null or dateFim is null then 1
                                else 0
                             end)
                   and  1 = (case 
                                WHEN idCaracteristica is not null and se.SEG_CARACT_ID = idCaracteristica then 1
                                when idCaracteristica is null then 1
                                else 0
                            end)
              ORDER BY SE.SEG_NOME ASC)
       LOOP
          
          IF NOT listSeguros.EXISTS(AM."SEGURO") THEN
             listSeguros(AM."SEGURO") := AM."SEGURO";
             currentSubTotal."DATA" := 'TOTAL';
             currentSubTotal."CLIENTE" := 'TOTAL';
             currentSubTotal."SEGURO" := AM."SEGURO";
             currentSubTotal."STD" := 0;
             currentSubTotal."USD" := 0;
             currentSubTotal."EUR" := 0;
             mapSubTotal(AM."SEGURO") := currentSubTotal;
          END IF;
          currentSubTotal := mapSubTotal(AM."SEGURO");
          
          
          totalSTD := totalSTD + AM."STD";
          totalEUR := totalEUR + AM."EUR";
          totalUSD := totalUSD + AM."USD";
          
          currentSubTotal."STD" := currentSubTotal."STD"  + AM."STD";
          currentSubTotal."EUR" :=  currentSubTotal."EUR" + AM."EUR";
          currentSubTotal."USD" :=  currentSubTotal."USD" + AM."USD";
          mapSubTotal(AM."SEGURO") := currentSubTotal;
          
          AM."STD" := PACK_LIB.money(AM."STD");
          AM."EUR" := PACK_LIB.money(AM."EUR");
          AM."USD" := PACK_LIB.money(AM."USD");
          pipe row (AM);
       END LOOP;
       
       reportRow."USD" := PACK_LIB.money(totalUSD);
       reportRow."EUR" := PACK_LIB.money(totalEUR);
       reportRow."STD" := PACK_LIB.money(totalSTD);
       
       reportRow."DATA" := 'TOTAL';
       reportRow."CLIENTE" := 'TOTAL';
       reportRow."SEGURO" := 'TOTAL';
       nomeSeguro := mapSubTotal.FIRST;
       
       WHILE(nomeSeguro IS NOT NULL)
       LOOP
          currentSubTotal := mapSubTotal(nomeSeguro);
          currentSubTotal."USD" := PACK_LIB.money(currentSubTotal."USD");
          currentSubTotal."EUR" := PACK_LIB.money(currentSubTotal."EUR");
          currentSubTotal."STD" := PACK_LIB.money(currentSubTotal."STD");
          PIPE ROW(currentSubTotal);
          nomeSeguro := mapSubTotal.NEXT(nomeSeguro);
       END LOOP;
       
       PIPE ROW (reportRow);
       
    END;
    
    
    FUNCTION reportProducaoTravel (dateInicio date, dateFIm date) return PACK_REPORT.filterProducaoTravel pipelined
    IS 
       classPassenger TP_CLASS;
       classCtt TP_CLASS;
    BEGIN
       FOR vr IN (select vr.*
                    from VER_PRODUCAO_TRAVEL vr
                    WHERE( dateInicio IS NULL
                       OR dateFim IS NULL)
                       OR vr."DATA SF" BETWEEN dateInicio AND dateFim)
       LOOP
          classCtt := TP_CLASS(null, vr.CTT_ID);
          IF vr."PAIS DESTINO" IS NULL THEN
             vr."PAIS DESTINO" := classCtt.content.get('idPaisDestino');
          END IF;
          pipe row(vr);
       END LOOP;
    END;
    
    
    FUNCTION reportContaMoviment (dateInicio DATE, dateFim DATE, listConta tb_array_string) RETURN PACK_TYPE.filterReportContaMovimento PIPELINED
    IS
       pagamentos FLOAT;
       recebimentos FLOAT;
       creditos FLOAT;
       debitos FLOAT;
       
       reportRow PACK_TYPE.reportContaMovimento;
       total PACK_TYPE.reportContaMovimento;
       
       procedure useValue (valor IN OUT float)
       IS
       BEGIN
          IF valor IS NULL THEN valor := 0; END IF;
       END;
       
    BEGIN
       /*TYPE reportContaMovimento IS RECORD(
          -> "TIPO" VARCHAR2(30), 
          -> "CONTA" VARCHAR2(30), 
          -> "DESCRICAO" VARCHAR2(100), 
          -> "CREDITO" VARCHAR2(125), 
          -> "DEBITO" VARCHAR2(125)*/
          
       total."CREDITO" := 0;
       total."DEBITO" := 0;
       
       FOR I IN (SELECT CT.COUNT_ID AS "ID",
                       CASE
                          WHEN CT.COUNT_TCOUNT_ID = 2 THEN 'P'
                          ELSE 'B'
                       END AS "TIPO", -- Sigunifica que é conta do banco
                       CT.COUNT_NIB AS "CONTA",
                       CT.COUNT_DESC AS "DESCRICAO",
                       '' AS "CREDITO",
                       '' AS "DEBITO"
                    FROM T_ACCOUNT  CT
                    WHERE CT.COUNT_TCOUNT_ID IN (2, 3)
                    ORDER BY "TIPO" ASC, "CONTA" ASC
                    
                    )
       LOOP
          
          IF I."TIPO" = 'B' THEN  -- Para as conta bacos 
              pagamentos := 0;
              recebimentos := 0;
              creditos :=0;
              debitos := 0;
              
              -- Carregar todos os pagamentos feitos no intervalo do tempo
              SELECT SUM(PAY.PAY_VALUETOTAL) INTO pagamentos
                 FROM T_PAYMENT PAY
                 WHERE PAY.PAY_ACCOUNT_ID = I."ID"
                    AND (PAY.PAY_DTPAY BETWEEN dateInicio AND dateFim
                        OR (dateInicio is null AND dateFim IS NULL ));
                    
              --Carregar todos os recebimentos feitos no intervalo do tempo
              SELECT SUM(AM.AMORT_VALOR) INTO recebimentos
                 FROM T_AMORTIZACAO AM
                 WHERE (CAST(AM.AMORT_DTREG AS DATE) BETWEEN dateInicio AND dateFim
                           OR (dateInicio is null AND dateFim IS NULL ))
                    AND AM.AMORT_ACCOUNT_ID = I."ID";
                    
             -- Carregar todas as movimentações do creditos da conta
             SELECT SUM(MOV.MOV_VALOR) INTO creditos
                FROM T_MOVIMENT MOV
                   WHERE MOV.MOV_COUNT_DESTINATION = I."ID"
                      AND (CAST(MOV.MOV_DTREG AS DATE) BETWEEN dateInicio AND dateFim
                           OR (dateInicio is null AND dateFim IS NULL ));
                      
                      
              -- Carregar todas as movimentações do creditos da conta
             SELECT SUM(MOV.MOV_VALOR) INTO creditos
                FROM T_MOVIMENT MOV
                   WHERE MOV.MOV_COUNT_DESTINATION = I."ID"
                      AND (CAST(MOV.MOV_DTREG AS DATE) BETWEEN dateInicio AND dateFim
                           OR (dateInicio is null AND dateFim IS NULL ));
              
              useValue(recebimentos);
              useValue(pagamentos);
              useValue(creditos);
              useValue(debitos);
              
              -- RECORD("TIPO" VARCHAR2(30), "CONTA" VARCHAR2(30), "DESCRICAO" VARCHAR2(100), "CREDITO" VARCHAR2(125), "DEBITO" VARCHAR2(125));
              reportRow."TIPO" := 'Conta banco';
              reportRow."CONTA" := I."CONTA";
              reportRow."DESCRICAO" := I."DESCRICAO";
              reportRow."CREDITO" := recebimentos + creditos;
              reportRow."DEBITO" := pagamentos + debitos;
              
              
          -- Para as contas de pagemntos carregar todos os pagamentos dos item feito usado a conta como foce o seu saldo    
          ELSIF I."TIPO" = 'P' THEN
             pagamentos := 0;
             SELECT SUM (ITEM.IPAY_VALUE) INTO pagamentos -- Pagamento as Credito in accounto payment
                FROM T_ITEMPAYMENT ITEM
                   INNER JOIN T_PAYMENT PAY ON ITEM.IPAY_PAY_ID = PAY.PAY_ID
                WHERE ITEM.IPAY_ACCOUNT_ID = I."ID"
                   AND (PAY.PAY_DTPAY BETWEEN dateInicio AND dateFim
                        OR (dateInicio is null AND dateFim IS NULL ));
                   
             useValue(pagamentos);
             reportRow."TIPO" := 'Conta pagamento';
             reportRow."CONTA" := I."CONTA";
             reportRow."DESCRICAO" := I."DESCRICAO";
             reportRow."CREDITO" := pagamentos;
             reportRow."DEBITO" := '';
          END IF;
          
          total."CREDITO" := total."CREDITO" + reportRow."CREDITO";
          total."DEBITO" := total."DEBITO" + reportRow."DEBITO";
          
          
          -- Se nao for expecifica do a conta a se procurar entao carregra todas as conta
          IF listConta IS NULL OR listConta.COUNT = 0 THEN
             reportRow."CREDITO" := PACK_LIB.MONEY(reportRow."CREDITO");
             reportRow."DEBITO" := PACK_LIB.MONEY(reportRow."DEBITO");
             PIPE ROW(reportRow);
          ELSE 
              -- Caso for ex+ecificado as contas a se carregar então carregar somente as conta na lista de expecificacao
              FOR J IN 1..listConta.COUNT LOOP
                 IF  I."TIPO"||'-'||I."ID" = listConta(J) THEN
                    PIPE ROW(reportRow);
                    EXIT;
                 END IF;
              END LOOP;
          END IF;
          
       END LOOP;
       
       total."DEBITO" := PACK_LIB.MONEY(total."DEBITO");
       total."CREDITO" := PACK_LIB.MONEY(total."CREDITO");
       
       PIPE ROW(total);
       
       -- Pintar a tabela de resutadado
    END;
    
    
    
    FUNCTION reportTaxaProducao(dataInicio DATE, dataFim DATE, valorNicon FLOAT) RETURN PACK_TYPE.filterReportTaxaProducao PIPELINED
    IS 
       niconComisionCod CHARACTER VARYING(30) := 'niconComisao';
       taxa PACK_TYPE.reportTaxaProducao;
       total PACK_TYPE.reportTaxaProducao;
       percentMotor FLOAT := 1.081; -- Percentagem a ser aplicar para motor
       percentNaoMotor FLOAT := 1.056; -- Percentaagem a ser aplicada a nao motor
       
       fga FLOAT := 0.025;
       consumo FLOAT := 0.05;
       selo FLOAT := 0.006;
       liquido FLOAT;
    BEGIN
       /*
      TYPE reportTaxaProducao IS RECORD("CATEGORIA" CHARACTER VARYING(30), "VALOR TOTAL" CHARACTER VARYING (125), "VALOR LIQUIDO" CHARACTER VARYING(125), "FGA" CHARACTER VARYING(125), "CONSUMO" CHARACTER VARYING (125), "SELO" CHARACTER VARYING (125));
      TYPE filterReportTaxaProducao IS TABLE OF reportTaxaProducao;
    
      */
      total."FGA":=0;
      total."CONSUMO" := 0;
      total."SELO" := 0;
      total."VALOR TOTAL" :=0;
      total."VALOR LIQUIDO" := 0;
      total."CATEGORIA" := 'Total';
      FOR I IN(SELECT  CAR.CARACT_DESC AS "CAT",
                       CAR.CARACT_ID AS "ID",
                       CASE 
                          WHEN CAR.CARACT_ID = 1 OR CAR.CARACT_ID = 2 THEN -- Quando for as caracterisca motor ou nao motor entao selecione o somatiro de todos os contratos
                              (SELECT SUM(CTO.CTT_VPAGAR * TAXA.TX_VENDA)
                                  FROM T_CONTRATO CTO
                                     INNER JOIN T_SEGURO SE ON CTO.CTT_SEG_ID = SE.SEG_ID
                                     INNER JOIN TABLE(PACK_CONTA.GETTAXADAY(CTO.CTT_DTREG, CTO.CTT_MOE_ID)) TAXA ON 1 = 1
                                  WHERE SE.SEG_CARACT_ID = CAR.CARACT_ID
                                      AND (CAST(CTO.CTT_DTCONTRATO AS DATE) BETWEEN dataInicio AND dataFim
                                      OR (dataInicio IS NULL AND dataFim IS NULL)))
                          ELSE valorNicon
                      END AS "VALOR"
                  FROM T_CARACTERISTICA CAR 
                     )
      LOOP
         --   , CHARACTER VARYING (125)
         taxa."CATEGORIA" := I."CAT";
         taxa."VALOR TOTAL" := PACK_LIB.MONEY(I."VALOR")/*||' STD'*/;
         total."VALOR TOTAL" := total."VALOR TOTAL" + I."VALOR";
         
         IF I."ID" = 1 THEN liquido := I."VALOR" / percentMotor; -- Para as caracteristica motor
         ELSE liquido  := I."VALOR" /percentNaoMotor; -- Pra as carracteristica nao motor
         END IF;
         
         taxa."VALOR LIQUIDO" := PACK_LIB.MONEY(liquido)/*||' STD'*/;
         total."VALOR LIQUIDO" := total."VALOR LIQUIDO" + liquido;
         
         -- O fga so pode ser aplicado aos seguro de carracteristica motor
         IF I."ID" = 1 THEN
            taxa."FGA" := PACK_LIB.MONEY((liquido * fga))/*||' STD'*/;
            total."FGA" := total."FGA" + (liquido * fga);
         ELSE taxa."FGA" := null;
         END IF;
         
         taxa."CONSUMO" := PACK_LIB.MONEY(liquido * consumo)/*||' STD'*/;
         total."CONSUMO" := total."CONSUMO" + liquido * consumo;
         
         taxa."SELO" := PACK_LIB.MONEY(liquido * selo)/*||' STD'*/;
         total."SELO" := total."SELO"  + liquido * selo;
         
         PIPE ROW(taxa);
      END LOOP;
      
      total."VALOR TOTAL" := PACK_LIB.money(total."VALOR TOTAL")/*||' STD'*/;
      total."VALOR LIQUIDO" := PACK_LIB.money(total."VALOR LIQUIDO")/*||' STD'*/;
      total."SELO" := PACK_LIB.money(total."SELO")/*||' STD'*/;
      total."CONSUMO" := PACK_LIB.money(total."CONSUMO")/*||' STD'*/;
      total."FGA" := PACK_LIB.money(total."FGA")/*||' STD'*/;
      
      PIPE ROW(total);
    END;
    
    
    FUNCTION reportTaxaNicon(dataInicio DATE, dataFim DATE) RETURN listValueContrato PIPELINED
    IS
    BEGIN
       FOR I IN (SELECT REPLACE(VAL.OBJVALL_VALUE, ',', '.') AS "VALOR"
                     FROM T_CONTRATO CTO
                        INNER JOIN T_OBJECTVALUE VAL ON CTO.CTT_ID = VAL.OBJVALL_CTT_ID
                        INNER JOIN T_OBJCLASSATTRIBUTE VAL_NAME ON VAL.OBJVALL_CLASSATB_ID = VAL_NAME.CLASSATB_ID
                        INNER JOIN T_SEGURO SE ON CTO.CTT_SEG_ID = SE.SEG_ID 
                     WHERE VAL_NAME.CLASSATB_NAME = 'niconComisao' --Corresponde ao atibuto que possui o valor da comisao nicon
                        AND VAL.OBJVALL_STATE = 1
                        AND CTO.CTT_CTT_ID IS NULL
                        AND SE.SEG_CARACT_ID = 3 
                        AND (CAST(CTO.CTT_DTCONTRATO AS DATE) BETWEEN dataInicio AND dataFim
                                      OR (dataInicio IS NULL AND dataFim IS NULL)))
      LOOP
         PIPE ROW(I."VALOR");
      END LOOP;
    END;
END PACK_REPORT;