create or replace FUNCTION FUNC_ALTERAR_ESTADOCONTRATO
(
   idUser NUMBER,
   idContrato NUMBER,
   novoEstado NUMBER, -- {-1 - ANULAR, 2 - Suspender, 1 - Reativar, 3 - Alterar data contrato}
   observacao VARCHAR,
   dataInicio DATE,
   dataFim DATE
)
RETURN VARCHAR2
IS
   linhaContrato T_CONTRATO%ROWTYPE;
   linhaLinha T_LINHACONTRATO%ROWTYPE;
   dateRenovacao DATE;
   dateFinalizar DATE;
   intervaloSuspensao FLOAT :=0;
   
   tt NUMBER;
BEGIN
   -- Obter as informacoes do seguro
   SELECT * INTO linhaContrato
      FROM T_CONTRATO CT
      WHERE CT.CTT_ID = idContrato;
  
  -- Obter a informaçao da ultima linha do seguro
   SELECT * INTO linhaLinha
      FROM T_LINHACONTRATO LC
      WHERE LC.LCTT_CTT_ID = idContrato
         AND LC.LCTT_STATE  = 1;
         
  dateFinalizar := linhaContrato.CTT_DTFIM;
  dateRenovacao := linhaContrato.CTT_DTRENOVACAO;
      
  IF linhaContrato.CTT_STATE = -1 THEN RETURN 'Esse contrato já está anulado!'; END IF;
  IF novoEstado = 1 
      OR novoEstado = -1
      OR novoEstado = 2
      OR novoEstado = 3 THEN
      
      -- Alterar o estado do contrato
      UPDATE T_CONTRATO CT
          SET CT.CTT_STATE = (CASE 
                                 WHEN novoEstado = 3 THEN CT.CTT_STATE
                                 ELSE novoEstado 
                              END) 
          WHERE CT.CTT_ID = idContrato;
          
       -- Caso o antigo estava suspenso
      IF linhaLinha.LCTT_FORSTATE = 2 AND novoEstado = 1 THEN
         -- O tempo em que o contrato estava suspenso
         dateFinalizar := linhaLinha.LCTT_DTFINALIZAR + (SYSDATE - linhaLinha.LCTT_DTREG);
         dateRenovacao := linhaLinha.LCTT_DTRENOVACAO + (SYSDATE - linhaLinha.LCTT_DTREG);
         intervaloSuspensao := PACK_LIB.getIntervalNumber(SYSDATE, linhaLinha.LCTT_DTREG);
      ELSIF novoEstado = 2 OR novoEstado = 1 THEN
      
         dateFinalizar := linhaLinha.LCTT_DTFINALIZAR;
         dateRenovacao := linhaLinha.LCTT_DTRENOVACAO;
         intervaloSuspensao := 0;
         
      ELSIF novoEstado = 3 THEN
         dateFinalizar := linhaLinha.LCTT_DTFINALIZAR + (dataInicio - linhaLinha.LCTT_DTINICIAR);
         dateRenovacao := linhaLinha.LCTT_DTRENOVACAO + (dataInicio - linhaLinha.LCTT_DTINICIAR);
         intervaloSuspensao := PACK_LIB.getIntervalNumber(dataInicio, linhaLinha.LCTT_DTINICIAR);
         
         UPDATE T_CONTRATO CT
            SET CT.CTT_DTINICIO = dataInicio
            WHERE CT.CTT_ID = idContrato;
      END IF;
      
      UPDATE T_LINHACONTRATO LC
         SET LC.LCTT_STATE = 0
         WHERE LC.LCTT_STATE = 1
            AND LC.LCTT_CTT_ID = idContrato;
            
      SELECT * INTO  linhaContrato
         FROM T_CONTRATO CT 
         WHERE CT.CTT_ID = idContrato;
            
     
          
      INSERT INTO T_LINHACONTRATO (LCTT_CTT_ID,
                                   LCTT_USER_ID,
                                   LCTT_OBS,
                                   LCTT_FORSTATE,
                                   LCTT_DTFINALIZAR,
                                   LCTT_DTRENOVACAO,
                                   LCTT_DTINICIO,
                                   LCTT_DTFIM,
                                   LCTT_INTERVAL,
                                   LCTT_DTINICIAR)
                                   VALUES(idContrato,
                                          idUser,
                                          observacao,
                                          novoEstado,
                                          dateFinalizar,
                                          dateRenovacao,
                                          dataInicio,
                                          dataFim,
                                          intervaloSuspensao,
                                          linhaContrato.CTT_DTINICIO);
        UPDATE T_CONTRATO CT
            SET CT.CTT_DTRENOVACAO = dateRenovacao,
                CT.CTT_DTFIM = dateFinalizar
            WHERE CT.CTT_ID = idContrato;
      -- Se for para reativar o contrato entao recalcular a data do contrato
      
      RETURN 'true';
  END IF;
  RETURN 'Contrato não foi alterado. Novo estado não reconhecido!';
  
END FUNC_ALTERAR_ESTADOCONTRATO;