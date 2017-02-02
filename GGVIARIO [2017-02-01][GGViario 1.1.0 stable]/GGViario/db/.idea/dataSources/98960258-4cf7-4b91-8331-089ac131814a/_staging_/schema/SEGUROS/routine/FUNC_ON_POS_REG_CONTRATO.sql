create or REPLACE FUNCTION FUNC_ON_POS_REG_CONTRATO
(
   idUser NUMBER, -- O utilizador que registrou o conctrato
   idContrato NUMBER, -- A identificacao do contrato registreado
   idSeguro NUMBER, -- O seguro a qual o contrato pertence
   numSegurado NUMBER, -- A quantidade de segurados encontrado no contrato NUM{n caso tiver segurado | 0 se nao tiver nehum segurado}
   numSubContratos NUMBER, -- numSubContartos {0 - para outros contrato | *(numero contarto selecionados) para multrisco}
   idSubContrato CHARACTER VARYING, -- SO APLICADO PARA MULTI SEGUROS {   ID_1,ID_2,ID_3,...,ID_N   }
   
   sumNicomComision FLOAT,
   sumPremio FLOAT, -- 
   sumTotal FLOAT,
   
   result NUMBER -- RESULT {1 - Java result has Sucesso | -1 Java result Has insucess}
)
RETURN CHARACTER VARYING
IS
   contrato T_CONTRATO%ROWTYPE;
   idTypeMoviment NUMBER;
   iConsumo FLOAT;
   iSelo FLOAT;
   iFga FLOAT;
   numDay NUMBER;
   provisao FLOAT;
   taxaVenda FLOAT := 1;
   taxa T_TAXA%ROWTYPE;
   money CHARACTER VARYING(1000);
BEGIN
   IF result = 1 THEN 
      -- FIRS REVALID IN DATA BASE THE RESULT OF REGISTER CONTRAT  
      
      
      -- LOAD HERE CONTRACT OTHER's DATA's
      SELECT * INTO contrato
         FROM T_CONTRATO  CT
         WHERE CT.CTT_ID = idContrato;
         
      -- LOado imposto consumo
      SELECT I.PERCENTAGEM/100 INTO iConsumo
         FROM VER_IMPOSTOS_TAXAS I
         WHERE I.NOME = 'CONSUMO';
         
      -- Loado imposto selo
      SELECT I.PERCENTAGEM/100 INTO iSelo
         FROM VER_IMPOSTOS_TAXAS I
         WHERE I.NOME = 'SELO';
         
       -- Loado imposto selo
      SELECT I.PERCENTAGEM/100 INTO iFga
         FROM VER_IMPOSTOS_TAXAS I
         WHERE I.NOME = 'FGA';
      
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
      
      
      -- UPDATE THE AFETDE MATERIALIZENDs VIEWs
      PRC_REFRESH_MVIEWS('OBJECT_VALUES');
           
        
      
      FOR OP IN(SELECT *
                   FROM VER_OPERACTION_DESTINO_ACCOUNT OP
                   WHERE OP."OPERACAO COD" = 'REG'
                      AND OP."SEGURO ID" = idSeguro)
      LOOP
         idTypeMoviment := NULL;
         /*
            TIPO MOVIMENTO{
                    WHEN TMOV_ID = 1 THEN 'DEBITO'
                    WHEN TMOV_ID = 2 THEN 'CREDITO'
            }
         */
            
         IF OP."TIPO MOVIMENTO" = 'DEBITO' THEN idTypeMoviment := 1; -- DEBITO AS 1
         ELSIF OP."TIPO MOVIMENTO" = 'CREDITO' THEN idTypeMoviment := 2; -- CREDITO AS 2
         END IF;
        
         IF OP.VALOR='SELO' AND OP.SEGURO != 'TIN' THEN
            PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (contrato.CTT_PBRUTO * taxaVenda) * iSelo, contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
        
         ELSIF OP.VALOR='IC' AND OP.SEGURO != 'TIN' THEN
            PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (contrato.CTT_PBRUTO * taxaVenda) * iConsumo, contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
        
         ELSIF OP.VALOR = 'PREMIO TOTAL' AND OP.SEGURO != 'TIN'  THEN
            PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (contrato.CTT_VPAGAR * taxaVenda), contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
        
         ELSIF OP.VALOR = 'PREMIO BRUTO' AND OP.SEGURO != 'TIN' THEN
            PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (contrato.CTT_PBRUTO * taxaVenda), contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
        
         ELSIF OP.SEGURO = 'MV' AND OP.VALOR = 'FGA' THEN
            PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (contrato.CTT_PBRUTO * taxaVenda) * iFga, contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
            
         ELSIF OP.VALOR = 'PROVISAO' THEN
            numDay := contrato.CTT_DTFIM - contrato.CTT_DTINICIO;
            IF numDay >= 365 THEN
               provisao := (contrato.CTT_VPAGAR) * 0.3;
            ELSE
               provisao := (contrato.CTT_VPAGAR) * 0.1;
            END IF;
            PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (provisao * taxaVenda), contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
            
         ELSIF OP.SEGURO = 'TIN' THEN -- ON POS REG SEGURO VIAGEM DO         
            /*
            TIN{
                 + NC
              }
            */
                 
            IF OP.VALOR = 'NC' THEN
               -- First get the NC of contracat
               -- TODO Para onde vai o somatorio dos NC que esta sen do calculado na aplicacao
               -- TODO obter esse  valor e tranferi em credito para a conta referenciada
               PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (sumNicomComision * taxaVenda), contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
          
            ELSIF OP.VALOR = 'PREMIO BRUTO' THEN
               PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (sumPremio * taxaVenda), contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
               
            ELSIF OP.VALOR = 'IC' THEN 
               PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (sumNicomComision * taxaVenda) * iConsumo, contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
               
            ELSIF OP.VALOR = 'PREMIO TOTAL' THEN
               PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (contrato.CTT_VPAGAR * taxaVenda), contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
               
            ELSIF OP.VALOR = 'SELO' THEN
               PRC_REG_MOVIMENTATION_PAYMENT(idUser, null, OP."CONTA DESTINO", idTypeMoviment, (sumNicomComision * taxaVenda) * iSelo, contrato.CTT_DTCONTRATO, contrato.CTT_ID, 'REG.CTT', OP.VALOR);
            END IF;
         END IF;
      END LOOP;
      
   END IF;
   
   RETURN 'true;OK';
END;