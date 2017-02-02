create or REPLACE PACKAGE BODY PACK_CONTA AS

  FUNCTION loadPrestacaoContrato (idContrato NUMBER) RETURN PACK_TYPE.filterPrestacao PIPELINED AS
  BEGIN
      FOR I IN(SELECT PRE.PREST_ID AS "ID",
                      PACK_LIB.MONEY(PRE.PREST_VALOR) AS "VALOR",
                      TO_CHAR(PRE.PREST_DTPRAZO, 'DD-MM-YYYY') AS "DATA",
                      PRE.PREST_VALOR AS "VALOR_SF",
                      PACK_LIB.MONEY(PRE.PREST_VALORPAGO) AS "PAGO",
                      PRE.PREST_VALORPAGO AS "PAGO_SF",
                      CASE
                         WHEN PRE.PREST_STATE = 3 THEN 'Por Pagar'
                         WHEN PRE.PREST_STATE = 2 THEN 'Em pagamento'
                         ELSE 'Pago'
                      END 
                  FROM T_PRESTACAO PRE
                  WHERE PRE.PREST_CTT_ID = idContrato)
      LOOP
        PIPE ROW (I);
      END LOOP;
  END loadPrestacaoContrato;
  
  
  
  FUNCTION toSTD (moneyValue FLOAT, idMoeda NUMBER) RETURN VARCHAR2
  IS
     linhaTaxa T_TAXA%ROWTYPE;
  BEGIN
     IF hasTaxaTOMoney(idMoeda) = 0 THEN RETURN 'falte;'||FUNC_ERROR('NO TAXA'); END IF;
     
     SELECT * INTO linhaTaxa
        FROM(SELECT TAX.*
                FROM T_TAXA TAX
                WHERE TAX.TX_MOE_BASE = idMoeda
                   AND TAX.TX_MOE_ID = 149
                   AND TAX.TX_STATE = 1
                ORDER BY TAX.TX_DTREG DESC)
         WHERE ROWNUM <= 1
     ;
     
     RETURN 'true;'|| (moneyValue* linhaTaxa.TX_COMPRA);
  END;
   
   
   FUNCTION fromSTD (stdValue FLOAT, idMoeda NUMBER) RETURN VARCHAR2
   IS
      linhaTaxa T_TAXA%ROWTYPE;
   BEGIN
       IF hasTaxaTOMoney(idMoeda) = 0 THEN RETURN 'falte;'||FUNC_ERROR('NO TAXA'); END IF;
     
    SELECT * INTO linhaTaxa
        FROM(SELECT TAX.*
                FROM T_TAXA TAX
                WHERE TAX.TX_MOE_BASE = idMoeda
                   AND TAX.TX_MOE_ID = 149
                   AND TAX.TX_STATE = 1
                ORDER BY TAX.TX_DTREG DESC)
         WHERE ROWNUM <= 1;
     
     RETURN 'true;'|| (stdValue/linhaTaxa.TX_VENDA);
   END;
   
   
   
   FUNCTION hasTaxaTOMoney(idMoeda number) RETURN NUMBER
   IS
      countTaxa NUMBER;
   BEGIN
       SELECT COUNT(*) INTO countTaxa 
       FROM T_TAXA T
       WHERE T.TX_MOE_BASE = idMoeda
          AND T.TX_MOE_ID = 149
          AND T.TX_STATE = 1 ;
       
       IF countTaxa >0 THEN countTaxa := 1; 
       ELSE countTaxa := 0;
       END IF;
       
       RETURN countTaxa;
   END;
   
   
   FUNCTION nextPaymentCod(idModoPaymet NUMBER) RETURN NUMBER IS
      tt NUMBER;
   BEGIN

      SELECT MAX(PAY_ID)+1 into tt
        FROM t_payment;

      IF tt IS NULL THEN tt := 1; END IF;
      RETURN tt;
  END;


   
  FUNCTION getPastCheque (idAccount NUMBER) RETURN NUMBER
  IS 
     idPastCheque NUMBER;
     tt NUMBER;
  BEGIN
     SELECT COUNT(*) INTO tt
        FROM T_CHEQUE CH
        WHERE CH.CHEQUE_TIME = 0
           AND CH.CHEQUE_ACCOUNT_ID = idAccount;
        
     IF tt = 1 THEN
        SELECT CH.CHEQUE_ID INTO idPastCheque
           FROM  T_CHEQUE CH
           WHERE CH.CHEQUE_TIME = 0
              AND CH.CHEQUE_ACCOUNT_ID = idAccount;
              
        RETURN idPastCheque;
     ELSE
        INSERT INTO T_CHEQUE (CHEQUE_USER_ID,
                              CHEQUE_TIME,
                              CHEQUE_ACCOUNT_ID,
                              CHEQUE_SEQINICIO,
                              CHEQUE_SEQFIM,
                              CHEQUE_TTCHEQUE,
                              CHEQUE_STATE)
                              VALUES(1,
                                     0,
                                     idAccount,
                                     -1,
                                     -1,
                                     0,
                                     0)
                                     RETURNING CHEQUE_ID INTO idPastCheque;
                                     
        RETURN idPastCheque;
     END IF;
  END;
      
  FUNCTION func_reg_payemnt (idUser NUMBER,
                            idAccount NUMBER,
                            datePayment DATE,
                            valueTotal FLOAT,
                            idModPayment NUMBER,
                            idFormaPayment NUMBER,
                            numDocumentPayment VARCHAR2,                              
                            codPayment VARCHAR2,
                            timePayment NUMBER,
                            numChequeRange CHARACTER VARYING) RETURN VARCHAR2
   IS
      accountRow VER_ACCOUNT%ROWTYPE;
      idPayment NUMBER;
      listResp TB_ARRAY_STRING;
      idCheque NUMBER;
      tt NUMBER;
      resp CHARACTER VARYING(900);
   BEGIN
      SELECT * INTO accountRow
         FROM VER_ACCOUNT T
         WHERE T.ID = idAccount;
      
      IF accountRow.SALDO < valueTotal THEN
         RETURN 'false;'||FUNC_ERROR('NO SALDO');
      END IF;


      -- Quando for o pagemento por cheque validar o pagamento
      IF idFormaPayment = 2 AND timePayment = 1 THEN
          resp := PACK_CONTA.VALIDATENUMCHEQUE(idAccount, numDocumentPayment, numChequeRange);
          listResp := PACK_LIB.SPLITALL(resp, ';');
          IF UPPER(listResp(1)) != UPPER('TRUE') THEN RETURN resp; END IF;
          
          idCheque := TO_NUMBER(listResp(2));
          
      ELSIF idFormaPayment = 2 AND timePayment = 0 THEN
           SELECT COUNT(*) INTO tt
              FROM T_PAYMENT PAY
              WHERE PAY.PAY_OBJ_FORMAPAYMENT = 2
                 AND PAY.PAY_STATE != -1
                 AND UPPER(PAY.PAY_DOCMENTPAYMENT) = UPPER(numDocumentPayment);
          IF tt != 0 THEN 
             RETURN 'false;'||FUNC_ERROR('CHEQUE ALERED IN USE');
          END IF;
          idCheque := getPastCheque(idAccount);
      END IF;
      
      INSERT INTO T_PAYMENT (PAY_ACCOUNT_ID,
                             PAY_DTPAY,
                             PAY_VALUETOTAL,
                             PAY_MPAY_ID,
                             PAY_OBJ_FORMAPAYMENT,
                             PAY_DOCMENTPAYMENT,
                             PAY_COD,
                             PAY_USER_ID,
                             PAY_TIME,
                             PAY_CHEQUE)
                             VALUES (idAccount,
                                      datePayment,
                                      valueTotal,
                                      idModPayment,
                                      idFormaPayment,
                                      numDocumentPayment,
                                      codPayment,
                                      idUser,
                                      timePayment,
                                      numChequeRange)
                                      RETURNING PAY_ID INTO idPayment;
      RETURN 'true;'||idPayment;
   END;
   
   
   FUNCTION func_reg_itempayment(idUser NUMBER,
                                 idPayment NUMBER,
                                 idContaPayment NUMBER,
                                 numeroDocumento VARCHAR,
                                 beneficiario VARCHAR2,
                                 quantity NUMBER,
                                 itenValue FLOAT,
                                 obs VARCHAR2,
                                 typeOperation NUMBER,
                                 retencaoFonte NUMBER
                                 ) RETURN VARCHAR2
   IS
      valorSTD DOUBLE PRECISION;
      taxaContaPayment T_TAXA%ROWTYPE;
      taxaContaBanco T_TAXA%ROWTYPE;
      payment T_PAYMENT%ROWTYPE;
      contaBanco T_ACCOUNT%ROWTYPE;
      contaPayment T_ACCOUNT%ROWTYPE;
   BEGIN
           
       INSERT INTO T_ITEMPAYMENT (IPAY_PAY_ID,
                                  IPAY_USER_ID,
                                  IPAY_ACCOUNT_ID,
                                  IPAY_NUNDOCUMENT,
                                  IPAY_BENEFICIARIO,
                                  IPAY_QUANTITY,
                                  IPAY_VALUE,
                                  IPAY_DESC,
                                  IPAY_TMOV_ID,
                                  IPAY_RETENCAOFONTE
                                  )
                                  VALUES(idPayment,
                                         idUser,
                                         idContaPayment,
                                         numeroDocumento,
                                         beneficiario,
                                         quantity,
                                         itenValue,
                                         obs,
                                         typeOperation,
                                         retencaoFonte
                                  );
                                         
      RETURN 'true;Sucess';
   END;
   
   FUNCTION func_end_payment(idPayment NUMBER,
                              idUser NUMBER) RETURN CHARACTER VARYING
   IS
     payment T_PAYMENT%ROWTYPE;
     sumCredito FLOAT;
     sumDebito FLOAT;
     diferencaCredito FLOAT;
     retencaoAccount NUMBER;
     tt NUMBER;
     operacao VER_OPERATION_ACCOUNT%ROWTYPE;
     imposto T_IMPOSTOTAXA%ROWTYPE;
   BEGIN

     -- Item do pagamento vai a debito
     -- Retencao na fonte de cada item vai credito
     -- O valor total do pagamento vai credito

    /*
      item = 200 000
      creditar conta 0.2 * 200 000

    */

       SELECT * INTO payment
          FROM T_PAYMENT PAY
          WHERE PAY.PAY_ID = idPayment;

      -- Aumentar o credito da conta
      PRC_REG_MOVIMENTATION_PAYMENT(
        idUser,
        payment.PAY_ACCOUNT_ID,
        2, -- as credito
        payment.PAY_VALUETOTAL,
        sysdate,
        payment.PAY_ID,
        'REG.PAY',
        'VALOR TOTAL'
      );

     -- O valor de cada item do pagamento vai ao demito as suas conta
     -- Quando hover retencao na fonte o valor vai para a conta da retencao na fonte
     FOR i IN (
       SELECT *
         FROM T_ITEMPAYMENT IPAY
         WHERE IPAY.IPAY_PAY_ID = payment.PAY_ID
     )
     LOOP

       -- Quando hover retencao na fonte
       IF i.IPAY_RETENCAOFONTE = 1 THEN
         SELECT COUNT(*) INTO tt
           FROM VER_OPERATION_ACCOUNT OP
           WHERE OP.GROUP_COD = 'REG.PAY'
              AND OP.VALUE = 'RETENCAO'
              AND OP.AFETAVEL_COD = 'DEFAULT';

         SELECT COUNT(*) INTO tt
             FROM T_IMPOSTOTAXA IT
                INNER JOIN T_IMPOSTOS CA ON IT.IMPTAX_IMP_ID = CA.IMP_ID
             WHERE CA.IMP_NAME = 'RETENCAO'
              AND IT.IMPTAX_STATE = 1
              AND tt != 0;

         IF tt != 0 THEN
           SELECT * INTO operacao
             FROM VER_OPERATION_ACCOUNT OP
             WHERE OP.GROUP_COD = 'REG.PAY'
                AND OP.VALUE = 'RETENCAO'
                AND OP.AFETAVEL_COD = 'DEFAULT';

           SELECT IT.* INTO imposto
             FROM T_IMPOSTOTAXA IT
                INNER JOIN T_IMPOSTOS CA ON IT.IMPTAX_IMP_ID = CA.IMP_ID
             WHERE CA.IMP_NAME = 'RETENCAO'
              AND IT.IMPTAX_STATE = 1;

           PRC_REG_MOVIMENTATION_PAYMENT(
               idUser,
               operacao.ACCOUNT_ID,
               operacao.TYPEMOVIMENT_ID,
               i.IPAY_VALUE * (imposto.IMPTAX_PERCENTAGEM/100),
               sysdate,
               i.IPAY_ID,
               operacao.GROUP_COD,
               operacao.VALUE
           );

         END IF;
       END IF;
     END LOOP;
      
      RETURN 'true;Sucesso';
   END;
   
   
    FUNCTION func_reg_chequeconta (idUser NUMBER,
                                   idAccount NUMBER,
                                   sequenceInicio VARCHAR2,
                                   sequenceFim VARCHAR2,
                                   ttCheques NUMBER)RETURN VARCHAR2
    IS 
       tt NUMBER;
    BEGIN
       
      IF LENGTH(sequenceInicio) <7
         OR LENGTH(sequenceFim) <7
      THEN
         RETURN 'false;Tamanho da sequenicia invalida';
      END IF;
       --Verificara se o numero  de cheque intercala com o numero de cheque da outra carteira
       SELECT COUNT(*) INTO tt 
          FROM T_CHEQUE CH
          WHERE To_NUMBER(sequenceInicio) BETWEEN TO_NUMBER(CH.CHEQUE_SEQINICIO) AND TO_NUMBER(CH.CHEQUE_SEQFIM)
              OR TO_NUMBER(sequenceFim) BETWEEN TO_NUMBER(CH.CHEQUE_SEQINICIO) AND TO_NUMBER(CH.CHEQUE_SEQFIM);
      
       -- Quando a sequeci entra na sequencia de outro cheque
       IF tt != 0 THEN
          RETURN 'false;'||FUNC_ERROR('CHEQUE SEQ INTERCALA');
       END IF;
       
       -- Quando a sequencia inicio for maior que a sequiencia final
       IF TO_NUMBER(sequenceInicio)> TO_NUMBER(sequenceFim) THEN 
          RETURN 'false;'||FUNC_ERROR('CHEQUE INICIO > FIM');
       END IF;
       
       -- Desabilitar o atual cheque da conta
       UPDATE T_CHEQUE CH
          SET CH.CHEQUE_STATE  = 0,
              CH.CHEQUE_DTFIM = SYSTIMESTAMP
          WHERE CH.CHEQUE_STATE = 1
             AND CH.CHEQUE_ACCOUNT_ID = idAccount;
       
       -- Criar o novo cheque para a conta
       INSERT INTO T_CHEQUE (CHEQUE_ACCOUNT_ID,
                             CHEQUE_USER_ID,
                             CHEQUE_SEQINICIO,
                             CHEQUE_SEQFIM,
                             CHEQUE_TTCHEQUE)
                             VALUES (idAccount,
                                     idUser,
                                     sequenceInicio,
                                     sequenceFim,
                                     ttCheques);
       RETURN 'true;Sucesso';
    END;
   
   
   FUNCTION funcGetNumCheque(accountId NUMBER)  RETURN VARCHAR2
   IS
      chequeRow T_CHEQUE%ROWTYPE;
      tt NUMBER;
      nunCheque VARCHAR2(30);
   BEGIN
      
      -- Verificar a disponibilidade de cheque para essa conta
      SELECT COUNT(*) INTO tt 
         FROM T_CHEQUE CH
         WHERE CH.CHEQUE_ACCOUNT_ID = accountId
            AND CH.CHEQUE_STATE = 1
            AND CH.CHEQUE_TTDESTRIBUIDO < CH.CHEQUE_TTCHEQUE
            AND LENGTH(CH.CHEQUE_SEQINICIO) >=7;
         
      IF tt = 0 THEN 
         RETURN 'false;'||FUNC_ERROR('NO CHEQUE AVAILABLE');
      END IF;
      
      -- Obter as informaçõe do cheque disponivel
      SELECT * INTO chequeRow
         FROM ( SELECT *
                   FROM T_CHEQUE CH
                   WHERE CH.CHEQUE_ACCOUNT_ID = accountId
                      AND CH.CHEQUE_STATE = 1
                      AND CH.CHEQUE_TTDESTRIBUIDO < CH.CHEQUE_TTCHEQUE
                      AND CH.CHEQUE_DTFIM IS NULL
                    ORDER BY CH.CHEQUE_DTREG DESC)
         WHERE ROWNUM <= 1;
      
      nunCheque := SUBSTR(chequeRow.CHEQUE_SEQINICIO,1, LENGTH(chequeRow.CHEQUE_SEQINICIO)-7);
      
     RETURN'true;'||nunCheque;
    
   END;
   
   
   FUNCTION validateNumCheque (accountId NUMBER, numDocumento CHARACTER VARYING, numCheque VARCHAR) RETURN VARCHAR2
   IS
      tt NUMBER;
      chequeRow T_CHEQUE%ROWTYPE;
   BEGIN
      -- Verificar a disponibilidade de cheque para essa conta
      SELECT COUNT(*) INTO tt 
         FROM T_CHEQUE CH
         WHERE CH.CHEQUE_ACCOUNT_ID = accountId
            AND CH.CHEQUE_STATE = 1
            AND CH.CHEQUE_TTDESTRIBUIDO < CH.CHEQUE_TTCHEQUE;
            
      IF tt = 0 THEN 
         RETURN 'false;'||FUNC_ERROR('NO CHEQUE AVAILABLE');
      END IF;
      
      -- Obter as informaçõe do cheque disponivel
      SELECT * INTO chequeRow 
         FROM ( SELECT *
                   FROM T_CHEQUE CH
                   WHERE CH.CHEQUE_ACCOUNT_ID = accountId
                      AND CH.CHEQUE_STATE = 1
                      AND CH.CHEQUE_TTDESTRIBUIDO < CH.CHEQUE_TTCHEQUE
                      AND CH.CHEQUE_DTFIM IS NULL
                    ORDER BY CH.CHEQUE_DTREG DESC)
         WHERE ROWNUM <= 1;
            
      SELECT COUNT(*) INTO tt 
         FROM T_PAYMENT PA 
         WHERE PA.PAY_OBJ_FORMAPAYMENT = 2 -- SIGUNIFICA QUE É TIPO CHEQUE
            AND PA.PAY_DOCMENTPAYMENT = numDocumento
            AND PA.PAY_STATE != -1; -- Exepto se o cheque não tenha sido anulado
            
      IF tt != 0 THEN
         RETURN 'false;'||FUNC_ERROR('CHEQUE ALERED IN USE');
      END IF;
      
      IF TO_NUMBER(numCheque) BETWEEN TO_NUMBER(chequeRow.CHEQUE_SEQINICIO)  AND TO_NUMBER(chequeRow.CHEQUE_SEQFIM) THEN
         RETURN 'true;'||chequeRow.CHEQUE_ID;
      ELSE RETURN 'false;'||FUNC_ERROR('CHEQUE OUT RANGE');
      END IF;
      
  END;
   
  /**
      A PROCESSAR NA APLICACAO
      NO CREDITO O QUE SAI DINHEIRO
         - null <no account source>
         - account destination
         - type moviment equals 1
      NO DEBITO O QUE ENTRA DINHEIRO
         - account source
         - null <no account destination>
         - type movimentation equal 2
         
  */
  FUNCTION regMovimentation (idUser NUMBER,
                            idAccountSource NUMBER,
                            idAccountDestination NUMBER,
                            idTypeMoviment NUMBER,
                            valueMovimentation FLOAT,
                            descrision VARCHAR2) RETURN VARCHAR2
  IS
     linhaAccountSource VER_ACCOUNT%ROWTYPE;
     linhaAccountDestination VER_ACCOUNT%ROWTYPE;
     taxa T_TAXA%ROWTYPE;
     contaValue DOUBLE PRECISION;
     tt NUMBER;
  BEGIN
      contaValue := valueMovimentation;
      
      IF idAccountSource IS NOT NULL THEN
         SELECT * INTO linhaAccountSource
            FROM VER_ACCOUNT AC
            WHERE AC.ID = idAccountSource;
    
         IF linhaAccountSource.SALDO < valueMovimentation THEN
            RETURN 'false;'||FUNC_ERROR('NO SALDO');
         END IF;
      END IF;
      
      IF idAccountDestination IS NOT NULL THEN
          SELECT * INTO linhaAccountDestination
            FROM VER_ACCOUNT AC
            WHERE AC.ID = idAccountDestination;
      END IF;
         
       -- validar as movimentações
       IF idTypeMoviment = 3 AND ( idAccountDestination IS NULL OR idAccountSource IS NULL )THEN
          RETURN 'false;'||FUNC_ERROR('REQUIRE ACCOUNT TRANSFER');
       ELSIF idTypeMoviment =  2 AND idAccountSource IS NULL THEN
          RETURN 'false'||FUNC_ERROR('REQUIRE ACCOUNT OUT');
       ELSIF idTypeMoviment = 1 AND idAccountDestination IS NULL THEN
          RETURN 'false'||FUNC_ERROR('REQUIRE ACCOUNT IN');
       END IF;
       
       
       IF (idTypeMoviment = 3 AND idAccountDestination IS NOT NULL AND idAccountSource IS NOT NULL)
          OR (idTypeMoviment = 1 AND idAccountDestination IS NOT NULL)
          OR (idTypeMoviment = 2 AND idAccountSource IS NOT NULL)
       THEN
          /*
          IF idTypeMoviment = 3
             AND NOT PACK_CONTA.equalsMoney(linhaAccountSource.COUNT_MOE_ID, linhaAccountDestination.COUNT_MOE_ID) THEN

             SELECT COUNT(*) INTO tt
                FROM TABLE(getTaxaMoney(SYSDATE, linhaAccountSource.COUNT_MOE_ID, linhaAccountDestination.COUNT_MOE_ID));
                
             IF tt =0 THEN 
                RETURN 'false;'||FUNC_ERROR('NO TAXA FOUND BETWEEN ACCOUNTS');
             END IF;
             
             SELECT * INTO taxa
                FROM TABLE(getTaxaMoney(SYSDATE, linhaAccountSource.COUNT_MOE_ID, linhaAccountDestination.COUNT_MOE_ID));
                
             contaValue := valueMovimentation * taxa.TX_VENDA;
          END IF;
          */
          INSERT INTO T_MOVIMENT (MOV_COUNT_SOURCE,
                                  MOV_COUNT_DESTINATION,
                                  MOV_TMOV_ID,
                                  MOV_USER_ID,
                                  MOV_VALOR,
                                  MOV_DESC)
                                  VALUES (idAccountSource,
                                          idAccountDestination,
                                          idTypeMoviment,
                                          idUser,
                                          valueMovimentation,
                                          descrision);
          RETURN 'true;Success';
       END IF; 
       RETURN 'false;'||FUNC_ERROR('MOVMENT NOT REG');
  END;
  
  
  FUNCTION getTaxaDay(dateTaxa TIMESTAMP, idMoeda NUMBER) RETURN PACK_CONTA.TAXA PIPELINED
  IS 
  BEGIN
     FOR I IN (SELECT *
                   FROM (SELECT *
                            FROM T_TAXA TAX 
                            WHERE TAX.TX_MOE_ID = 149
                               AND TAX.TX_DTREG <= dateTaxa
                               AND TAX.TX_MOE_BASE = idMoeda
                            ORDER BY TAX.TX_DTREG DESC)
                   WHERE ROWNUM <= 1)
     LOOP
        PIPE ROW(I);
     END LOOP;
  END;
  
  

  FUNCTION getTaxaMoney(dateTaxa TIMESTAMP, idMoedaBase NUMBER, idMoeda NUMBER) RETURN PACK_CONTA.TAXA PIPELINED
  IS 
  BEGIN
     FOR I IN (SELECT *
                   FROM (SELECT *
                            FROM T_TAXA TAX 
                            WHERE TAX.TX_MOE_ID = idMoeda
                               AND TAX.TX_DTREG <= dateTaxa
                               AND TAX.TX_MOE_BASE = idMoedaBase
                            ORDER BY TAX.TX_DTREG DESC)
                   WHERE ROWNUM <= 1)
     LOOP
        PIPE ROW(I);
     END LOOP;
  END;
  
  
  FUNCTION getSTDMoney RETURN T_MOEDA%ROWTYPE IS
     std T_MOEDA%ROWTYPE;
  BEGIN
     SELECT * into std
       FROM T_MOEDA MD
       WHERE MD.MOE_SIGLA = 'STD';
       
     RETURN std;
  END;
  
  
  FUNCTION functLoadItemPayment(idPayment NUMBER) RETURN PACK_TYPE.filterItemPayment PIPELINED
  IS
  BEGIN
      -- TYPE itenPayment IS RECORD("ID" NUMBER, "CONTA" VARCHAR2(30), "DOCUMENTO" VARCHAR2(30), "BENEFICIARIO" VARCHAR2(160), 
      --"QUANTIDADE" FLOAT, "VALOR" VARCHAR2(120), "OBSERVACAO" VARCHAR2(200), REGISTRO VARCHAR2(100)) ;
     FOR PAY IN (SELECT PAY.IPAY_ID AS "ID",
                    AP."NUMBER" AS "CONTA",
                    PAY.IPAY_NUNDOCUMENT AS "DOCUMENTO",
                    PAY.IPAY_BENEFICIARIO AS "BENEFICIARIOA",
                    PAY.IPAY_QUANTITY AS "QUANTIDADE",
                    PACK_LIB.MONEY(PAY.IPAY_VALUE) AS "VALOR",
                    PAY.IPAY_DESC AS "OBS",
                    TO_CHAR(PAY.IPAY_DTREG, 'DD-MM-YYYY') AS REGISTRO
                  FROM T_ITEMPAYMENT PAY 
                     INNER JOIN VER_ACCOUNT AP ON PAY.IPAY_ACCOUNT_ID = AP.ID)
     LOOP
        PIPE ROW(PAY);
     END LOOP;
  END;
  
  
  
  FUNCTION functLoadChequesAccount (idAccount NUMBER) RETURN PACK_CONTA.listCheque PIPELINED
  IS
  BEGIN
      -- TYPE cheque IS RECORD ("ID" NUMBER, "INICO" VARCHAR2(30), "FIM" VARCHAR2(30), "TOTAL" NUMBER, "DESTRIBUIDO" NUMBER, "REGISTRO" VARCHAR2(30), "TERMINO" VARCHAR2(30) ,"ESTADO" VARCHAR2(30));
      FOR I IN (SELECT CH.CHEQUE_ID AS "ID",
                       CH.CHEQUE_SEQINICIO AS "INICIO",
                       CH.CHEQUE_SEQFIM AS "FIM",
                       CH.CHEQUE_TTCHEQUE AS "TOTAL",
                       CH.CHEQUE_TTDESTRIBUIDO AS "DESTRIBUIDO",
                       TO_CHAR(CH.CHEQUE_DTREG, 'DD-MM-YYYY') AS "REGISTRO",
                       CASE
                          WHEN CH.CHEQUE_DTFIM IS NULL THEN 'Indifinido' 
                          ELSE TO_CHAR(CH.CHEQUE_DTFIM, 'DD-MM-YYYY')
                        END AS "TERMINO",
                       CASE 
                          WHEN CH.CHEQUE_STATE = 1 THEN 'Aberto'
                          ELSE 'Fechado'
                       END AS "ESTADO"
                   FROM T_CHEQUE CH
                   WHERE CH.CHEQUE_ACCOUNT_ID = idAccount
                      AND TO_NUMBER(CH.CHEQUE_SEQFIM) != -1
                      AND TO_NUMBER(CH.CHEQUE_SEQINICIO) != -1)
      LOOP
          PIPE ROW (I);
      END LOOP;
  END;
  
  
  FUNCTION functLoadMoviment(idAccount NUMBER, idTipoMovimento NUMBER) RETURN listMoviment PIPELINED
  IS
  BEGIN
     -- TYPE moviment IS RECORD("ID" NUMBER, "VALOR" VARCHAR2(120), "TIPO MOVIMENTO" VARCHAR2(50), "OUTRA CONTA" VARCHAR2(120),
     -- "INFORMACAO" VARCHAR2(200), "REGISTRO" VARCHAR2(20));
   
     FOR I IN (SELECT MV.MOV_ID  AS  "ID",
                      PACK_LIB.MONEY(MV.MOV_VALOR) AS "VALOR",
                      TMV.TMOV_DESC AS "TIPO MOVIMENTO",
                      (CASE 
                         WHEN MV.MOV_TMOV_ID = 1 OR MV.MOV_TMOV_ID = 2 THEN 'Nenhuma' 
                         WHEN MV.MOV_COUNT_DESTINATION = idAccount THEN 'PARA '||ASOURCE."NUMBER"
                         ELSE 'DE '||DEST."NUMBER"
                      END) AS "OUTRA CONTA",
                      MV.MOV_DESC AS "INFORMACAO",
                      TO_CHAR(MV.MOV_DTREG, 'DD-MM-YYYY')
                      
                  FROM T_MOVIMENT MV
                     INNER JOIN T_TYPEMOVIMENTO TMV ON MV.MOV_TMOV_ID = TMV.TMOV_ID
                     LEFT JOIN VER_ACCOUNT ASOURCE ON MV.MOV_COUNT_SOURCE = ASOURCE.ID
                     LEFT JOIN VER_ACCOUNT DEST ON MV.MOV_COUNT_DESTINATION = DEST.ID
                  WHERE (MV.MOV_COUNT_SOURCE = idAccount
                            OR MV.MOV_COUNT_DESTINATION = idAccount)
                         AND( MOV_TMOV_ID = idTipoMovimento 
                            OR idTipoMovimento IS NULL))
     LOOP
        PIPE ROW(I);
     END LOOP;
  END;
  
  
  FUNCTION funcRegNewPercentagem(idUser NUMBER, idImposto NUMBER, percentage FLOAT, valorMaximo FLOAT) RETURN CHARACTER VARYING
  IS
     linhaImposto T_IMPOSTOS%ROWTYPE;
  BEGIN
      SELECT * INTO linhaImposto
         FROM T_IMPOSTOS IMP
         WHERE IMP.IMP_ID  = idImposto;
         
      -- DESABILITAR O VALOR ANTIGO PARA ESSE IMPOSTO
      UPDATE T_IMPOSTOTAXA P
         SET P.IMPTAX_STATE = 0
         WHERE (P.IMPTAX_MAXVALOR = valorMaximo OR P.IMPTAX_MAXVALOR IS NULL)
            AND P.IMPTAX_IMP_ID = idImposto;
            
      INSERT INTO T_IMPOSTOTAXA (IMPTAX_IMP_ID,
                                 IMPTAX_USER_ID,
                                 IMPTAX_MAXVALOR,
                                 IMPTAX_PERCENTAGEM)
                                        VALUES(idImposto,
                                               idUser,
                                               valorMaximo,
                                               percentage);
      RETURN 'true';
  END;
  
  
  FUNCTION funcRegComisao(idUser NUMBER, idFuncionario NUMBER, idContrato NUMBER, valorPercentagem FLOAT, dataComisao DATE) RETURN CHARACTER VARYING
  IS
     existComisao NUMBER;
     comisaoRow T_COMISAO%ROWTYPE;
     linhaContrato T_CONTRATO%ROWTYPE;
     valorComisaoContrato FLOAT;
  BEGIN
  
    -- Verificar se esse contrato possui alguma comisao aplicada a ela
     SELECT COUNT(*) INTO existComisao
        FROM T_COMISAO COM
        WHERE COM.COMISAO_CTT_ID = idContrato
           AND COM.COMISAO_STATE != -1;
      
    -- Se exitir alguma comisaa aplicada a ela entao abortar o registro
    IF existComisao = 0 THEN
       RETURN 'false;'||FUNC_ERROR('COMISAO OF CONTRATO IS APLIED');
    END IF;
    
     -- Verificar se existe a comisao do tipo pacote registrada
     SELECT COUNT(*) INTO existComisao
        FROM T_COMISAO COM 
        WHERE COM.COMISAO_FUNC_ID = idFuncionario
           AND COM.COMISAO_COMISAO_ID IS NULL
           AND COM.COMISAO_CTT_ID IS NULL
           AND COM.COMISAO_DATA IS NULL
           AND COM.COMISAO_PERCENTAGEM IS NULL
           AND COM.COMISAO_STATE = 1;
      
      -- Carregar as inforamcoes do contrato em comisao
      SELECT * INTO linhaContrato
         FROM  T_CONTRATO CT
         WHERE CT.CTT_ID = idContrato;
         
    valorComisaoContrato := (valorPercentagem /100) * linhaContrato.CTT_VPAGAR;
    
    -- Se nao exitir a comisoa do tipo pacote entao cria-la
    IF existComisao = 0 THEN
       INSERT INTO T_COMISAO(COMISAO_USER_ID,
                             COMISAO_FUNC_ID)
                             VALUES(idUser,
                                    idFuncionario);
    END IF;
    
    -- CORRESPONDE A COMISAO
    SELECT * INTO comisaoRow
        FROM T_COMISAO COM 
        WHERE COM.COMISAO_FUNC_ID = idFuncionario
           AND COM.COMISAO_COMISAO_ID IS NULL
           AND COM.COMISAO_CTT_ID IS NULL
           AND COM.COMISAO_DATA IS NULL
           AND COM.COMISAO_PERCENTAGEM IS NULL
           AND COM.COMISAO_STATE = 1;
           
     INSERT INTO T_COMISAO (COMISAO_USER_ID,
                            COMISAO_FUNC_ID,
                            COMISAO_CTT_ID,
                            COMISAO_PERCENTAGEM,
                            COMISAO_DATA,
                            COMISAO_COMISAO_ID,
                            COMISAO_VALOR)
                            VALUES(idUser,
                                   idFuncionario,
                                   idContrato,
                                   valorPercentagem,
                                   dataComisao,
                                   comisaoRow.COMISAO_ID,
                                   valorComisaoContrato
                                   );
                                   
     -- Aumetar o total de comisao mensal que o funcionario tem direito                 
     UPDATE T_COMISAO CM
         SET CM.COMISAO_VALOR = CM.COMISAO_VALOR + valorComisaoContrato
         WHERE CM.COMISAO_ID = comisaoRow.COMISAO_ID;
      RETURN 'true;Sucess';
        
  END;
  
  
  FUNCTION funcUpdateAccount(idAccount NUMBER, idUser NUMBER, newDesiginacao CHARACTER VARYING) RETURN CHARACTER VARYING
  IS
     tt NUMBER;
  BEGIN
     UPDATE T_ACCOUNT AC
       SET AC.ACCOUNT_DESC = newDesiginacao
       WHERE AC.ACCOUNT_ID = idAccount;

     RETURN 'true;Sucesso';
  END;
  
  
  FUNCTION functLoadEstrutura RETURN ListEstrutura PIPELINED
  IS
     estrutura PACK_CONTA.EstruturaSalarial;
     estruturaSomatorio PACK_CONTA.EstruturaSalarial;
     somatorio FLOAT;
     iCount NUMBER;
     
     PROCEDURE clearr(linha IN OUT PACK_CONTA.EstruturaSalarial)
     IS 
     BEGIN
        linha."NIVEL 1" := 0;
        linha."NIVEL 2" := 0;
        linha."NIVEL 3" := 0;
        linha."NIVEL 4" := 0;
        linha."NIVEL 5" := 0;
        linha."NIVEL 6" := 0;
        linha."NIVEL 7" := 0;
     END;
     
     PROCEDURE finalize (linha IN OUT PACK_CONTA.EstruturaSalarial)
     IS
     BEGIN
        NULL;
       /*
         linha."TOTAL" := 0;
         IF linha."NIVEL 1" IS NOT NULL THEN 
            linha."TOTAL" := linha."TOTAL" + linha."NIVEL 1";
         ELSIF linha."NIVEL 2" IS NULL THEN
            linha."TOTAL" := linha."TOTAL" + linha."NIVEL 2";
         ELSIF linha."NIVEL 3" IS NULL THEN
            linha."TOTAL" := linha."TOTAL" + linha."NIVEL 3";
         ELSIF linha."NIVEL 4" IS NULL THEN
            linha."TOTAL" := linha."TOTAL" + linha."NIVEL 4";
         ELSIF linha."NIVEL 5" IS NULL THEN
            linha."TOTAL" := linha."TOTAL" + linha."NIVEL 5";
         ELSIF linha."NIVEL 6" IS NULL THEN
            linha."TOTAL" := linha."TOTAL" + linha."NIVEL 6";
         ELSIF linha."NIVEL 7" IS NULL THEN
            linha."TOTAL" := linha."TOTAL" + linha."NIVEL 7";
         END IF;
         
         linha."TOTAL" := PACK_LIB.money(linha."TOTAL")||' STD';
         linha."NIVEL 1" := PACK_LIB.money(linha."NIVEL 1")||' STD';
         linha."NIVEL 2" := PACK_LIB.money(linha."NIVEL 2")||' STD';
         linha."NIVEL 3" := PACK_LIB.money(linha."NIVEL 3")||' STD';
         linha."NIVEL 4" := PACK_LIB.money(linha."NIVEL 4")||' STD';
         linha."NIVEL 5" := PACK_LIB.money(linha."NIVEL 5")||' STD';
         linha."NIVEL 6" := PACK_LIB.money(linha."NIVEL 6")||' STD';
         linha."NIVEL 7" := PACK_LIB.money(linha."NIVEL 7")||' STD';
         */
     END;
  BEGIN
    NULL;
    /*
     clearr(estruturaSomatorio);
     clearr(estrutura);
     estruturaSomatorio."CATEGORIA" := 'TOTAL';
     
     
     FOR TCAT IN (SELECT *
                  FROM T_OBJECTYPE TCAT
                  WHERE OBJT_T_ID = 10 
                     AND OBJT_STATE = 1)
     LOOP
        estrutura."CATEGORIA" := TCAT.OBJT_DESC;
        iCount := 1;
        FOR CAT IN (SELECT * 
                       FROM T_CATEGORY CAT
                          INNER JOIN T_OBJECTYPE NIV ON CAT.CAT_OBJT_LEVELCAT = NIV.OBJT_ID
                       WHERE CAT.CAT_OBJT_TYPECATEGORY =  TCAT.OBJT_ID
                       ORDER BY NIV.OBJT_DESC ASC )
        LOOP
            somatorio := CAT.CAT_BASESALARY + CAT.CAT_HOUSESUBVENTION + CAT.CAT_LUNCHSUBVENTION + CAT.CAT_TRANSPORTSUBVENTION;
            
            IF iCount = 1 THEN
                estrutura."NIVEL 1" := somatorio;
                estruturaSomatorio."NIVEL 1" := estruturaSomatorio."NIVEL 1" + somatorio;
            ELSIF iCount = 2 THEN
               estrutura."NIVEL 2" := somatorio;
               estruturaSomatorio."NIVEL 2" := estruturaSomatorio."NIVEL 2" + somatorio;
            ELSIF iCount = 3 THEN
               estrutura."NIVEL 3" := somatorio;
               estruturaSomatorio."NIVEL 3" := estruturaSomatorio."NIVEL 3" + somatorio;
            ELSIF iCount = 4 THEN 
               estrutura."NIVEL 4" := somatorio;
               estruturaSomatorio."NIVEL 4" := estruturaSomatorio."NIVEL 4" + somatorio;
            ELSIF iCount = 5 THEN 
               estrutura."NIVEL 5" := somatorio;
               estruturaSomatorio."NIVEL 5" := estruturaSomatorio."NIVEL 5" + somatorio;
            ELSIF iCount = 6 THEN
               estrutura."NIVEL 6" := somatorio;
               estruturaSomatorio."NIVEL 6" := estruturaSomatorio."NIVEL 6" + somatorio;
            ELSIF iCount = 7 THEN
               estrutura."NIVEL 7" := somatorio;
               estruturaSomatorio."NIVEL 7" := estruturaSomatorio."NIVEL 7" + somatorio;
            END IF;
            iCount := iCount +1;
        END LOOP;
        
        finalize(estrutura);
        PIPE ROW(estrutura);
        clearr(estrutura);
     END LOOP;
     
     finalize(estruturaSomatorio);
     PIPE ROW(estruturaSomatorio);
     */
  END;
  
  FUNCTION functLoadComisao RETURN ListComisao PIPELINED
  IS
     totalComisao PACK_CONTA.Comisao;
  BEGIN
     NULL;
     /*
     TYPE comisao IS RECORD 
        -> "ID" NUMBE
        -> "ID CONTRATO" NUMBER
        -> "ID FUNCIONARIO" NUMBER
        -> "DATA" CHARACTER VARYING(20)
        -> "FUNCIONARIO" CHARACTER VARYING(200)
        -> "SEGURO" CHARACTER VARYING(200)
        -> "CONTRATO" CHARACTER VARYING(200)
        -> "VALOR" CHARACTER VARYING(200)
        -> "REGISTRO" CHARACTER VARYING(20)
        -> "ESTADO" CHARACTER VARYING(50));
     */
    /*
     totalComisao."VALOR" := 0;
     FOR COMISAO IN (SELECT COMISAO.COMISAO_ID AS "ID",
                            CTT.CTT_ID AS "ID CONTRATO",
                            F.FUNC_ID AS "ID FUNCIONARIO",
                            TO_CHAR(COMISAO.COMISAO_DATA, 'DD-MM-YYYY') AS "DATA",
                            F.FUNC_NOME||' '||F.FUNC_APELIDO AS "FUNCIONARIO",
                            SE.SEG_CODIGO AS "SEGURO",
                            CTT.CTT_EXTERNALCOD AS "CONTRATO",
                            CAST(COMISAO.COMISAO_VALOR AS VARCHAR2(200))AS "VALOR",
                            TO_CHAR(COMISAO.COMISAO_DTREG, 'DD-MM-YYYY') AS "REGISTRO",
                            (CASE 
                                WHEN COMISAO.COMISAO_STATE = 1 THEN 'Ativo'
                                ELSE 'Processado'
                            END) AS "ESTADO"
                        FROM T_COMISAO COMISAO
                           INNER JOIN T_CONTRATO CTT ON COMISAO.COMISAO_CTT_ID = CTT.CTT_ID
                           INNER JOIN T_FUNCIONARIO F ON COMISAO.COMISAO_FUNC_ID = F.FUNC_ID
                           INNER JOIN T_SEGURO SE ON CTT.CTT_SEG_ID  = SE.SEG_ID
                        WHERE COMISAO.COMISAO_STATE != -1
                           AND COMISAO.COMISAO_COMISAO_ID IS NOT NULL)
     LOOP
        totalComisao."VALOR" := totalComisao."VALOR" + COMISAO."VALOR";
        COMISAO."VALOR" := PACK_LIB.money(COMISAO."VALOR");
        PIPE ROW(COMISAO);
     END LOOP;
     
     totalComisao."VALOR" := PACK_LIB.money(totalComisao."VALOR");
     PIPE ROW(totalComisao);
    */
  END;
  
  
  FUNCTION functAlterStatePayment(idUser NUMBER, idPayment INTEGER, novoEstado NUMBER,  observacao CHARACTER VARYING) RETURN CHARACTER VARYING
  IS 
     payment T_PAYMENT%ROWTYPE;
  BEGIN
    /*
    -- DEPOIS DE REGISTRAR O PAGAMENTO DEMINUIR o SALDO NA CONTA
   UPDATE T_ACCOUNT AC 
      SET AC.COUNT_SALDO = AC.COUNT_SALDO - :NEW.PAY_VALUETOTAL,
          AC.COUNT_SALDODEBITO = AC.COUNT_SALDODEBITO + :NEW.PAY_VALUETOTAL
      WHERE AC.COUNT_ID = :NEW.PAY_COUNT_ID;
      
   -- Se for um pagamento via cheque reitara o sequencia do seu cheque
   IF :NEW.PAY_OBJ_FORMAPAYMENT = 2 THEN
      -- retirar um cheque da cateira ou desabiliatar a carateira atual do cheque
      UPDATE T_CHEQUE  CH
         SET CH.CHEQUE_STATE = (CASE WHEN CH.CHEQUE_TTDESTRIBUIDO +1 = CH.CHEQUE_TTCHEQUE THEN 0 ELSE 1 END ),
             CH.CHEQUE_TTDESTRIBUIDO = CH.CHEQUE_TTDESTRIBUIDO + 1
         WHERE CH.CHEQUE_STATE = 1
             AND CH.CHEQUE_COUNT_ID = :NEW.PAY_COUNT_ID;
   END IF;-- DEPOIS DE REGISTRAR O PAGAMENTO DEMINUIR o SALDO NA CONTA
   UPDATE T_ACCOUNT AC 
      SET AC.COUNT_SALDO = AC.COUNT_SALDO - :NEW.PAY_VALUETOTAL,
          AC.COUNT_SALDODEBITO = AC.COUNT_SALDODEBITO + :NEW.PAY_VALUETOTAL
      WHERE AC.COUNT_ID = :NEW.PAY_COUNT_ID;
      
   -- Se for um pagamento via cheque reitara o sequencia do seu cheque
   IF :NEW.PAY_OBJ_FORMAPAYMENT = 2 THEN
      -- retirar um cheque da cateira ou desabiliatar a carateira atual do cheque
      UPDATE T_CHEQUE  CH
         SET CH.CHEQUE_STATE = (CASE WHEN CH.CHEQUE_TTDESTRIBUIDO +1 = CH.CHEQUE_TTCHEQUE THEN 0 ELSE 1 END ),
             CH.CHEQUE_TTDESTRIBUIDO = CH.CHEQUE_TTDESTRIBUIDO + 1
         WHERE CH.CHEQUE_STATE = 1
             AND CH.CHEQUE_COUNT_ID = :NEW.PAY_COUNT_ID;
   END IF;
    */
     -- Carregar o pagemnto
     SELECT * INTO payment
        FROM T_PAYMENT PAY 
        WHERE PAY.PAY_ID = idPayment;
        
     -- Quando o pagamento esta anulado entao abortar qualquer proxima operacao
     IF payment.PAY_STATE = -1 THEN 
        RETURN 'false;'||func_error('PAYMENT IS ANULED');
     END IF;
     
     -- Validar se o novo estado é reconhecido na base de dados
     IF novoEstado NOT IN (-1) THEN 
        RETURN 'false;Operacao Invalida, Operacao = '||novoEstado;
     END IF;
     
     -- Quando o novo estado for anular entao
     IF novoEstado = -1 THEN
     
        UPDATE T_LINHAPAYMENT LP
           SET LP.LPAY_STATE = 0
           WHERE LP.LPAY_STATE = 1
              AND LP.LPAY_PAY_ID = idPayment;
        
        INSERT INTO T_LINHAPAYMENT(LPAY_USER_ID,
                                   LPAY_PAY_ID,
                                   LPAY_OBS,
                                   LPAY_FORSTATE)
                                   VALUES(idUser,
                                          idPayment,
                                          observacao,
                                          novoEstado);
        -- Anular o pagamento
        UPDATE T_PAYMENT PA
           SET PA.PAY_STATE = -1
           WHERE PA.PAY_ID = idPayment;
           
        RETURN 'true;Sucesso';
     END IF;
    
  END;
  
  
   FUNCTION getNumConta (idCount NUMBER) RETURN CHARACTER VARYING
   IS
      numConta CHARACTER VARYING(90);
      conta VER_ACCOUNT%ROWTYPE;
   BEGIN
      SELECT * INTO conta
         FROM VER_ACCOUNT AC
         WHERE AC.ID = idCount;
         
     RETURN conta."NUMBER";
   END;
   
   
   -- RETURNS {1 - Igual | 0  - Diferente}
   FUNCTION equalsMoney(idMoeda1 NUMBER, idMoeda2 NUMBER) RETURN BOOLEAN
   IS
      moeda1 T_MOEDA%ROWTYPE;
      moeda2 T_MOEDA%ROWTYPE;
      resultBoolean NUMBER := 0;
   BEGIN
      -- Se as moedas forem completament igual então é verdadeira
      IF idMoeda1 = idMoeda2 THEN resultBoolean := 1;
      ELSE
          SELECT * INTO moeda1
             FROM T_MOEDA
             WHERE MOE_ID = idMoeda1;
             
          SELECT * INTO moeda2
             FROM T_MOEDA
             WHERE MOE_ID = idMoeda2;
             
             
          IF moeda1.MOE_NOME = moeda2.MOE_NOME THEN resultBoolean := 1; END IF;
       END IF;
      
      RETURN resultBoolean = 1;
   END;
  
  
   
END PACK_CONTA;