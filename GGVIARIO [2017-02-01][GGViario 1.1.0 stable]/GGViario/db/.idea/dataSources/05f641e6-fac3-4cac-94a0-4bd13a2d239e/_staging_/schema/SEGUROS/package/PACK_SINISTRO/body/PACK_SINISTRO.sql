create OR  REPLACE PACKAGE  BODY "PACK_SINISTRO" as

    FUNCTION FUNC_REG_OCORRENCIA(ID_USER NUMBER,
                                 ID_CTTOCORRENCIA NUMBER,
                                 residenciaPolicial VARCHAR2,
                                 residenciaSinistrado VARCHAR2,
                                 localInspecao VARCHAR2,
                                 DTINSPECAO DATE,
                                 HORA_DATAOCORRENCIA TIMESTAMP, 
                                 LOCALOCORRENCIA VARCHAR2,
                                 NARRACAO_SUCEDIDO VARCHAR2,
                                 ESTIMATIVA_RECUPERACAO VARCHAR2,
                                 NUMERO_VEICULOTERCEIRO VARCHAR2,
                                 NUMERO_CHASSI VARCHAR2,
                                 DESCRICAO_OCORRENCIA VARCHAR2, -- Como medidas tomdas
                                 idSuperOcorencia NUMBER,
                                 codigoSinistro CHARACTER VARYING
    ) RETURN VARCHAR2
    
    IS
      id_ocor number;
      idResidenciaPolicial NUMBER := PACK_REGRAS.GET_RESIDENCE(residenciaPolicial,ID_USER);
      idResidenciaSinistrado NUMBER := PACK_REGRAS.GET_RESIDENCE ( residenciaSinistrado,ID_USER);
      idLocalInspencao NUMBER  := PACK_REGRAS.GET_RESIDENCE(localInspecao,ID_USER);
      idlocalocorrencia NUMBER := PACK_REGRAS.GET_RESIDENCE(localocorrencia,ID_USER);
      
      hasAlteracao NUMBER := 0;
      tt NUMBER;
      currentOcorrencia T_OCORRENCIA%ROWTYPE;
      contrato T_CONTRATO%ROWTYPE;
      
      novo NUMBER := 0;
      missingAccount CHARACTER VARYING(1000);
      
      money CHARACTER VARYING(32);
      taxa T_TAXA%ROWTYPE;
      taxaVenda FLOAT := 1;
      idTypeMoviment NUMBER;
    BEGIN
        -- Quando o novo registro  for a atualizacao do antigo registro entao
          -- Garantir que para o novo registro tenha pelo menos um dados deferente
        IF idSuperOcorencia IS NOT NULL THEN
           SELECT COUNT(*) INTO hasAlteracao
              FROM T_OCORRENCIA OC
              WHERE OC.OCOR_CTT_ID = ID_CTTOCORRENCIA
                 AND OC.OCOR_OBJT_ENDERECOPOLICIAL = idResidenciaPolicial
                 AND OC.OCOR_OBJT_ENDERECOSINISTRADO = idResidenciaSinistrado
                 AND OC.OCOR_OBJT_LOCALINSPECAO = idLocalInspencao
                 AND OC.OCOR_DTINSPECAO =  DTINSPECAO
                 AND OC.OCOR_HORA = HORA_DATAOCORRENCIA 
                 AND OC.OCOR_OBJT_LOCAL = idlocalocorrencia
                 AND OC.OCOR_NARRACAOSUCEDIDO = NARRACAO_SUCEDIDO
                 AND OC.OCOR_ESTIMATIVARECUPERACAO = ESTIMATIVA_RECUPERACAO
                 AND OC.OCOR_NUMVEICULOTERCEIRO = NUMERO_VEICULOTERCEIRO
                 AND OC.OCOR_NUMCHASSI = NUMERO_CHASSI
                 AND OC.OCOR_DESC = DESCRICAO_OCORRENCIA
                 AND ((OC.OCOR_ID = idSuperOcorencia AND OC.OCOR_STATE != -1 AND OC.OCOR_OCOR_ID IS NULL)
                        OR OC.OCOR_OCOR_ID = idSuperOcorencia AND OC.OCOR_STATE != -1);
                        
           SELECT * INTO currentOcorrencia
               FROM T_OCORRENCIA OCR
               WHERE OCR.OCOR_ID = idSuperOcorencia;
           
           -- Se a correncia não estiver mais pendente então canselar a atualizacao    
           IF currentOcorrencia.OCOR_STATE != 1 THEN
               RETURN 'false;'||FUNC_ERROR('OCORENCI NOT PENDENTE');
           END IF;
                        
            -- DESABILITAR A OCORENCIA ATUAL            
            UPDATE T_OCORRENCIA OC
               SET OC.OCOR_STATE  = -1
               WHERE (OC.OCOR_ID = idSuperOcorencia AND OC.OCOR_OCOR_ID IS NULL AND OC.OCOR_STATE != -1)
                  OR (OC.OCOR_OCOR_ID = idSuperOcorencia AND OC.OCOR_STATE != -1);
        ELSE
           SELECT COUNT(*) INTO tt
              FROM T_OCORRENCIA OC
              WHERE OC.OCOR_COD = codigoSinistro;
              
           IF tt != 0 THEN 
              RETURN 'false;'||FUNC_ERROR('COD SINISTRO ALERED EXIST');
           END IF;
           
           novo := 1;
           
        END IF;
        
        SELECT * INTO contrato
           FROM T_CONTRATO CT
           WHERE CT.CTT_ID = ID_CTTOCORRENCIA;
           
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
        
        /*   
        missingAccount := PACK_VALIDATE.GETMISSINGACCOUNTOPERACTION(contrato.CTT_SEG_ID, 'SIN');
        IF missingAccount IS NOT NULL THEN
           RETURN 'false;'||missingAccount;
        END IF;
        */
        -- Se haver ao menos uma informação diferente entao atualizar criar o novo registro
        IF hasAlteracao = 0 THEN
          INSERT INTO T_OCORRENCIA(OCOR_USER_ID,
                                   OCOR_CTT_ID,
                                   OCOR_OBJT_ENDERECOPOLICIAL,
                                   OCOR_OBJT_ENDERECOSINISTRADO,
                                   OCOR_OBJT_LOCALINSPECAO,
                                   OCOR_DTINSPECAO,
                                   OCOR_HORA,
                                   OCOR_OBJT_LOCAL,
                                   OCOR_NARRACAOSUCEDIDO,
                                   OCOR_ESTIMATIVARECUPERACAO,
                                   OCOR_NUMVEICULOTERCEIRO,
                                   OCOR_NUMCHASSI,
                                   OCOR_DESC,
                                   OCOR_OCOR_ID,
                                   OCOR_COD)
                                   VALUES(ID_USER,
                                          ID_CTTOCORRENCIA,
                                          idResidenciaPolicial ,
                                          idResidenciaSinistrado,
                                          idLocalInspencao,
                                          DTINSPECAO,
                                          HORA_DATAOCORRENCIA,
                                          idlocalocorrencia,
                                          NARRACAO_SUCEDIDO,
                                          ESTIMATIVA_RECUPERACAO,
                                          NUMERO_VEICULOTERCEIRO,
                                          NUMERO_CHASSI,
                                          DESCRICAO_OCORRENCIA,
                                          idSuperOcorencia,
                                          codigoSinistro)RETURNING OCOR_ID into id_ocor ;
         END IF;
         
         
         FOR OP IN(SELECT *
                   FROM VER_OPERATION_ACCOUNT OP
                   WHERE OP.GROUP_COD = 'REG.SIN'
                      AND OP.AFETAVEL_COD  IN ( ''||contrato.CTT_SEG_ID, 'ALL'))
         LOOP
             idTypeMoviment := NULL;
             /*IF OP."TIPO MOVIMENTO" = 'DEBITO' THEN idTypeMoviment := 1; -- DEBITO AS 1
             ELSIF OP."TIPO MOVIMENTO" = 'CREDITO' THEN idTypeMoviment := 2; -- CREDITO AS 2
             END IF;
             */
             
             idTypeMoviment := OP.TYPEMOVIMENT_ID;

           IF OP.VALUE = 'SIN-VALUE' THEN
             PRC_REG_MOVIMENTATION_PAYMENT(ID_USER, OP.ACCOUNT_ID, idTypeMoviment, (contrato.CTT_VPAGAR * taxaVenda), contrato.CTT_DTCONTRATO, id_ocor, 'SIN.REG', OP.VALUE);
           END IF;
        END LOOP;
         
         IF idSuperOcorencia IS NOT NULL THEN
            id_ocor := idSuperOcorencia;
         END IF;
         
         
         return 'true;'|| id_ocor;  
    END;
      
      
    FUNCTION FUNC_REG_HIPOTECA(ID_USER NUMBER,
                                OCORRENCIA_HIPOTECA NUMBER,
                                NOME_RESIDENCIA VARCHAR2,
                                NOME_INTERESSADO varchar2,
                                idOldHipoteca NUMBER
                          )RETURN varchar2
    IS 
      id_hipo number;
      ID_RESIDENCIA NUMBER := PACK_REGRAS.GET_RESIDENCE(NOME_RESIDENCIA,ID_USER);
      hasHipoteca NUMBER := 0;
    BEGIN
        -- Quando a hipoteca for atulizacao da antiga hipoteca entao validar se houve alguma modificaçoes em 
        IF idOldHipoteca IS NOT NULL THEN
            SELECT COUNT(*) INTO hasHipoteca
               FROM T_HIPOTECA H
               WHERE H.HIPO_OCOR_ID = OCORRENCIA_HIPOTECA
                  AND H.HIPO_NOMEINTERESSADO = NOME_INTERESSADO
                  AND H.HIPO_OBJT_ENDERECO = ID_RESIDENCIA
                  AND H.HIPO_STATE != -1;
                  
            -- DESABILITAR  A TESTEMUNHA ACTUAL
            UPDATE T_HIPOTECA H
               SET H.HIPO_STATE = -1
               WHERE H.HIPO_ID = idOldHipoteca;
        END IF;
        
        -- So criar o registro se houver alteracoes na hipoteca
        IF hasHipoteca = 0 THEN
          insert into T_HIPOTECA(HIPO_USER_ID,
                                  HIPO_OBJT_ENDERECO,
                                  HIPO_OCOR_ID,
                                  HIPO_NOMEINTERESSADO)
                                  VALUES( ID_USER,
                                          ID_RESIDENCIA,
                                          OCORRENCIA_HIPOTECA,
                                          NOME_INTERESSADO) returning  hipo_id into id_hipo ;
       END IF;
                          
           
       RETURN 'true;'||id_hipo;
    END;
    
     
    FUNCTION FUNC_REG_TESTEMUNHAS (ID_USER NUMBER,
                                  OCORRENCIA_TESTEMUNHO NUMBER,
                                  NOME_RESIDENCIA varchar2,
                                  NOME_TESTEMUNHA VARCHAR2,
                                  TELEFONE_TESTEMUNHA VARCHAR2,
                                  idOldeTestemunha NUMBER
    
                                  )RETURN VARCHAR2
    IS 
      id_test number;
      ID_RESIDENCIA NUMBER := PACK_REGRAS.GET_RESIDENCE(NOME_RESIDENCIA,ID_USER);
      hasTestemunha NUMBER := 0;
    BEGIN
    
       -- QUANDO A TESTEMUNHA FOR UMA ATUALIZACAO 
       IF idOldeTestemunha IS NOT NULL THEN
           SELECT COUNT(*) INTO hasTestemunha
              FROM T_TESTEMUNHAS TT
              WHERE TT.TEST_OCOR_ID = OCORRENCIA_TESTEMUNHO
                 AND TT.TEST_NOME = NOME_TESTEMUNHA
                 AND TT.TEST_OBJT_ENDERECO = ID_RESIDENCIA
                 AND TT.TEST_TELEFONE = TELEFONE_TESTEMUNHA;
           
           -- DESABILITAR A TESTEMUNHA ACTUAL
           UPDATE T_TESTEMUNHAS TT
             SET TT.TEST_STATE = -1
             WHERE TT.TEST_STATE != -1
                AND TT.TEST_ID  = idOldeTestemunha;
       END IF;
       
       IF hasTestemunha = 0 THEN
          insert into T_TESTEMUNHAS(TEST_USER_ID,
                                    TEST_OCOR_ID,
                                    TEST_OBJT_ENDERECO,
                                    TEST_NOME,
                                    TEST_TELEFONE)
                                    VALUES( ID_USER,
                                            OCORRENCIA_TESTEMUNHO,
                                            ID_RESIDENCIA,
                                            NOME_TESTEMUNHA,
                                            TELEFONE_TESTEMUNHA)
                                    RETURNING  TEST_ID INTO id_test;
       END IF;
       
       RETURN 'true;'||id_test;
    END;


   FUNCTION FUNC_REG_SINISTROPAYMENT(idUser NUMBER, idOcorencia NUMBER, valorOcorencia FLOAT, observacao CHARACTER VARYING, dataPaymemte DATE)
   RETURN CHARACTER VARYING
   IS 
      ocorencia T_OCORRENCIA%ROWTYPE;
   BEGIN
       SELECT OCR.* INTO ocorencia
          FROM TABLE(PACK_SINISTRO.FUNCT_LOAD_OCORRENCIA(idOcorencia)) OCR;
          
          /*
            WHEN OC.OCOR_STATE = 1 THEN 'Pendente'
            WHEN OC.OCOR_STATE = 2 THEN 'Pago'
            WHEN OC.OCOR_STATE = 0 THEN 'Anulado'
            WHEN OC.OCOR_STATE = 3 THEN 'Pagamento solicitado'
          */
      -- So regitrar o pagamento se o sinistro estiver em um estado pendente
      IF ocorencia.OCOR_STATE NOT IN (1, 2) THEN 
         RETURN 'false;'||FUNC_ERROR('OCORENCI NOT PENDENTE');
      END IF;
          
       INSERT INTO T_SINISTROPAGAMENTO (SINPAY_USER_ID,
                                        SINPAY_OCOR_ID,
                                        SINPAY_VALUE,
                                        SINPAY_DTPAYMENT,
                                        SINPAY_OBS)
                                        VALUES(idUser,
                                               idOcorencia,
                                               valorOcorencia,
                                               dataPaymemte, 
                                               observacao);
        
        -- Colocar a ocorerencia no estado de pendencia do pagamento
        UPDATE T_OCORRENCIA OC
           SET OC.OCOR_STATE = 3
           WHERE OC.OCOR_ID = ocorencia.OCOR_ID;
       RETURN 'true;Success';
   END;
   
   
   FUNCTION FUNC_DISABLE_SINISTRO(idUser NUMBER, idOcorrencia NUMBER, observacao CHARACTER VARYING) RETURN CHARACTER VARYING
   IS
   BEGIN
      UPDATE T_OCORRENCIA O
         SET O.OCOR_STATE = 0
         WHERE (O.OCOR_ID = idOcorrencia AND O.OCOR_OCOR_ID IS NULL AND O.OCOR_STATE = 1)
            OR (O.OCOR_OCOR_ID = idOcorrencia AND O.OCOR_STATE = 1);
         
      UPDATE T_HIPOTECA H
         SET H.HIPO_STATE = 0
         WHERE H.HIPO_OCOR_ID = idOcorrencia;
         
      UPDATE T_TESTEMUNHAS T
         SET T.TEST_STATE = 0
         WHERE T.TEST_OCOR_ID = idOcorrencia;
        
      RETURN 'true;Sucess';
   END;
   
   
   FUNCTION FUNC_EDITE_SINISTRO (idUser NUMBER, idOcorrencia NUMBER) RETURN CHARACTER VARYING
   IS 
   BEGIN
       UPDATE T_OCORRENCIA  OC
          SET OC.OCOR_STATE = -1
          WHERE (OC.OCOR_ID = idOcorrencia AND OC.OCOR_STATE = 1 AND OC.OCOR_OCOR_ID IS NULL)
             OR (OC.OCOR_OCOR_ID = idOcorrencia AND OC.OCOR_STATE = 1);
   END;
   
   
   FUNCTION FUNCT_LOAD_OCORRENCIA(idOcorrencia NUMBER) RETURN OCORRENCIA PIPELINED
   IS
   BEGIN
      FOR OC IN(SELECT *
                  FROM T_OCORRENCIA OC
                  WHERE (OC.OCOR_ID = idOcorrencia AND OC.OCOR_OCOR_ID IS NULL AND OC.OCOR_STATE != -1)
                      OR OC.OCOR_OCOR_ID = idOcorrencia AND OC.OCOR_STATE != -1)
      LOOP
         IF OC.OCOR_OCOR_ID IS NULL THEN
            OC.OCOR_OCOR_ID := OC.OCOR_ID;
         END IF;
         PIPE ROW(OC);
      END LOOP;
   END;
   
   
   FUNCTION FUNCT_LOAD_TESTEMNUNHA(idOcorencia NUMBER) RETURN TESTEMNUNHA PIPELINED
   IS
   BEGIN
      FOR I IN(SELECT *
                  FROM T_TESTEMUNHAS TT
                  WHERE TT.TEST_OCOR_ID = idOcorencia
                     AND TT.TEST_STATE =1 )
      LOOP
         PIPE ROW(I);
      END LOOP;
   END;
   
   
   FUNCTION FUNCT_LOAD_HIPOTECA(idOcorencia NUMBER) RETURN HIPOTECA PIPELINED
   IS
   BEGIN
       FOR I IN (SELECT *
                    FROM  T_HIPOTECA I
                    WHERE I.HIPO_OCOR_ID = idOcorencia
                       AND I.HIPO_STATE = 1)
       LOOP
           PIPE ROW(I);
       END LOOP;
   END;
   
   
   FUNCTION FUNCT_LOAD_MAPAPAYMENT (dataInicio DATE, dataFim date) RETURN filterMapaPayment PIPELINED
   IS
      payment paymentMap;
      paymentTotal paymentMap;
      sumTotal FLOAT := 0;
      sumTotalPago DOUBLE PRECISION := 0;
   BEGIN
      --TYPE paymentMap IS RECORD("APOLICE" CHARACTER VARYING(120), "CLIENTE" CHARACTER VARYING(120), 
      --"VALOR" CHARACTER VARYING (120), "DATA" CHARACTER VARYING(20), "OBSERVACAO" CHARACTER VARYING(300));
    
      FOR I IN(SELECT *
                   FROM  T_SINISTROPAGAMENTO SIN 
                      INNER JOIN T_OCORRENCIA OC ON SIN.SINPAY_OCOR_ID = OC.OCOR_ID
                      INNER JOIN T_CONTRATO CT ON OC.OCOR_CTT_ID = CT.CTT_ID
                      INNER JOIN T_CLIENTE CL ON CT.CTT_CLI_ID = CL.CLI_ID
                      LEFT JOIN T_PAYMENT P ON SIN.SINPAY_PAY_ID = P.PAY_ID
                   WHERE SIN.SINPAY_DTPAYMENT BETWEEN dataInicio AND dataFim
                      OR (dataInicio IS NULL AND dataFim IS NULL)
                      AND OC.OCOR_STATE != -1
                   )
    LOOP
        payment."APOLICE" := I.CTT_NUMAPOLICE;
        IF I.CLI_TCLI_ID = 1 THEN -- Pessoa singula
           payment."CLIENTE" := I.CLI_NOME||' '||I.CLI_APELIDO;
        ELSE payment."CLIENTE" := I.CLI_NOME;
        END IF;
        
        CASE 
           WHEN I.PAY_ID IS NOT NULL AND I.PAY_STATE = -1 THEN payment."ESTADO" := 'Anulado';
           WHEN I.SINPAY_STATE  = 1 THEN payment."ESTADO" := 'Pago';
           WHEN I.SINPAY_STATE = 2 THEN payment."ESTADO" := 'Pendente';
           ELSE payment."ESTADO" := '';
        END CASE;
        
        IF I.SINPAY_STATE = 1 AND i.PAY_ID IS NOT NULL THEN
            payment."VALOR PAGO" := PACK_LIB.money(i.PAY_VALUETOTAL);
            sumTotalPago := sumTotalPago + i.PAY_VALUETOTAL;
        END IF;
        
        payment."SINISTRO" := I.OCOR_COD;
        payment."VALOR REQUISITADO" := PACK_LIB.MONEY(I.SINPAY_VALUE)/*||' STD'*/;
        payment."DATA" := TO_CHAR(I.SINPAY_DTPAYMENT, 'DD-MM-YYYY');
        payment."OBSERVACAO" := I.SINPAY_OBS;
        sumTotal := sumTotal + I.SINPAY_VALUE;
        PIPE ROW(payment);
    END LOOP;
    
    paymentTotal."VALOR REQUISITADO" := PACK_LIB.MONEY(sumTotal)/*||' STD'*/;
    paymentTotal."VALOR PAGO" := PACK_LIB.MONEY(sumTotalPago);
    paymentTotal."APOLICE" := 'TOTAL';
    PIPE ROW(paymentTotal);
    
   END;
   
   
   FUNCTION FUNC_PAY_SINISTRO (idUser NUMBER, idRequisicaoPagamento NUMBER, idPayment NUMBER) RETURN CHARACTER VARYING
   IS
      tt NUMBER;
      sinistroPayment T_SINISTROPAGAMENTO%ROWTYPE;
      ocorrencia T_OCORRENCIA%ROWTYPE;
   BEGIN
      SELECT COUNT(*) INTO tt
         FROM T_SINISTROPAGAMENTO SPAY
         WHERE SPAY.SINPAY_PAY_ID  = idPayment;
         
      SELECT * INTO sinistroPayment
         FROM T_SINISTROPAGAMENTO SPAY
         WHERE SPAY.SINPAY_ID = idRequisicaoPagamento;
         
     SELECT * INTO ocorrencia
        FROM TABLE(FUNCT_LOAD_OCORRENCIA(sinistroPayment.SINPAY_OCOR_ID));
         
      IF tt != 0 THEN 
          RETURN 'false;'||FUNC_ERROR('PAYMENT ALOWED REFERENCED TO SINISTRO');
      END IF;
      
      IF sinistroPayment.SINPAY_STATE != 2 THEN 
          RETURN 'false;'||FUNC_ERROR('SINISTRO PAYMENT NOT PENDENT');
      END IF;
      
      
      -- Expecificar que o pagamento refere-se ao pagamento de um sinistro
      UPDATE T_PAYMENT P
         SET P.PAY_SINISTRO = 1
         WHERE P.PAY_ID = idPayment;
         
      --  Expecificar que o pagamento para a requisisao ja foi emetida   
      UPDATE T_SINISTROPAGAMENTO  SPAY
         SET SPAY.SINPAY_PAY_ID  = idPayment,
             SPAY.SINPAY_STATE = 1
         WHERE SPAY.SINPAY_ID = idRequisicaoPagamento;
         
      -- Informar no sinistro que o pagamento para esse já foi efetuado
      UPDATE T_OCORRENCIA OCR 
         SET OCR.OCOR_STATE = 2
         WHERE OCR.OCOR_ID = ocorrencia.OCOR_ID;
         
      RETURN 'true;Sucesso';
   END;
   
                          
END PACK_SINISTRO ;