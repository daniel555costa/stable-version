create or REPLACE PROCEDURE "PRC_UPD_FUNCIONARIO"
(
    USER_ID IN VARCHAR2 ,
    typeAccao NUMBER, -- {1 - Registro do novo | 2 - tualizao antigo}
    ID_FUNCIONARIO NUMBER,
    RESIDENCIA IN VARCHAR2,
    ID_CATEGORIA NUMBER,
    ID_ESTADO_CIVIL NUMBER,
    MOVEL IN VARCHAR2,
    PHONE IN VARCHAR2,
    numFilhos NUMBER,
    nameFuncionario VARCHAR2,
    surnameFuncionario VARCHAR2,
    nif VARCHAR2,
    dataNascimento DATE,
    codNicon VARCHAR2,
    dataEntrada DATE,
    mail VARCHAR2,
    idNivelCategoriaSalarial NUMBER
) IS
    
    -- Buscra pela resindecia que sera registrada
    tt NUMBER;
    ttNif NUMBER;
    ID_RESIDENCIA NUMBER := PACK_REGRAS.GET_RESIDENCE(RESIDENCIA, USER_ID);
  
BEGIN
      --DESACTIVA O HISTORICO ANTIGO DO FUNCIONARIO
     UPDATE T_LINHAFUNCIONARIO 
        SET LFUNC_STATE = 0
        WHERE LFUNC_STATE = 1 
            AND LFUNC_FUNC_ID = ID_FUNCIONARIO;
            
            
      --CRIANDO UM NOVO HISTORICO PARA FUNCIONARIO
     INSERT INTO T_LINHAFUNCIONARIO(LFUNC_USER_ID,
                                    LFUNC_RES_ID,
                                    LFUNC_CAT_ID,
                                    LFUNC_SC_ID,
                                    LFUNC_MOVEL,
                                    LFUNC_PHONE,
                                    LFUNC_FUNC_ID,
                                    LFUNC_NUMFILHOS)
                                    VALUES( USER_ID,
                                            ID_RESIDENCIA,
                                            ID_CATEGORIA,
                                            ID_ESTADO_CIVIL,
                                            MOVEL,
                                            PHONE,
                                            ID_FUNCIONARIO,
                                            numFilhos);
    IF typeAccao = 2 THEN
       SELECT COUNT(*) INTO tt
          FROM T_FUNCIONARIO F
          WHERE F.FUNC_ID != ID_FUNCIONARIO
             AND F.FUNC_ACCESSNAME = codNicon;
       
       SELECT COUNT(*) INTO ttNif
          FROM T_FUNCIONARIO F
          WHERE F.FUNC_ID != ID_FUNCIONARIO
             AND F.FUNC_NIF = nif;
             
       UPDATE T_FUNCIONARIO F
          SET F.FUNC_NOME = nameFuncionario,
              F.FUNC_CODSEGURADORA = (CASE WHEN tt = 0 THEN codNicon ELSE F.FUNC_CODSEGURADORA END),
              F.FUNC_ACCESSNAME = (CASE WHEN tt = 0 THEN codNicon ELSE F.FUNC_CODSEGURADORA END),
              F.FUNC_APELIDO = surnameFuncionario,
              F.FUNC_DTENTRADA = dataEntrada,
              F.FUNC_DTNASC = dataNascimento,
              F.FUNC_MAIL = mail,
              F.FUNC_NIF = (CASE WHEN ttNif = 0 THEN nif ELSE F.FUNC_NIF END),
              F.FUNC_OBJT_LEVELCATEGORY = idNivelCategoriaSalarial
          WHERE F.FUNC_ID = ID_FUNCIONARIO;
    END IF;
    COMMIT WORK;
END PRC_UPD_FUNCIONARIO;