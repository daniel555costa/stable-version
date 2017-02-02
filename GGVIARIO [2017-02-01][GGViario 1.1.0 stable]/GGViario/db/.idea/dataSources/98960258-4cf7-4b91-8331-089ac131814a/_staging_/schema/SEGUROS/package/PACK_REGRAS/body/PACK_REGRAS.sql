create or REPLACE PACKAGE BODY "PACK_REGRAS" IS
    
    FUNCTION getObjectID(objectValue VARCHAR2, idUser NUMBER, typeObject NUMBER, valueSuper VARCHAR2, typeSuper NUMBER) RETURN VARCHAR2
    IS
       idObject NUMBER;
       idTypeSuper NUMBER;
    BEGIN
       -- Quando nao vier o valor do obljcto ou o seu tipo abortar a operacao
       IF objectValue IS NULL OR typeObject IS NULL THEN RETURN null; END IF;
       
       -- Se for informado o seu super efectuar uma busca recuresiva para obter o seu super
       IF valueSuper IS NOT NULL AND typeSuper IS NOT NULL THEN
           idTypeSuper := getObjectID(valueSuper, idUser, typeSuper, null, null);
       END IF;
       
       -- Verificar a existencia de objecto
       SELECT COUNT(*) INTO idObject
          FROM T_OBJECTYPE OBJ
          WHERE UPPER(OBJ.OBJT_DESC) = UPPER(objectValue)
             AND OBJ.OBJT_T_ID = typeObject;
             
      -- Quando existir obter o id
      IF idObject = 1 THEN
         SELECT OBJ.OBJT_ID INTO idObject
          FROM T_OBJECTYPE OBJ
          WHERE UPPER(OBJ.OBJT_DESC) = UPPER(objectValue)
             AND OBJ.OBJT_T_ID = typeObject;
      ELSE
         -- Se nao encontrar regustra como novo
         INSERT INTO T_OBJECTYPE(OBJT_T_ID,
                                 OBJT_USER_ID,
                                 OBJT_DESC,
                                 OBJT_OBJT_ID)
                                 VALUES(typeObject,
                                        idUser,
                                        objectValue,
                                        idTypeSuper)
                RETURNING OBJT_ID INTO idObject;
      END IF;
      
      RETURN idObject;
    END;
   
    
    FUNCTION REG_OBJECTO
    (
      USER_ID NUMBER, 
      ID_CONTRATO VARCHAR,
      TIPO_OBJECTO NUMBER,
      regAssegura NUMBER
    )RETURN PACK_TYPE.Resultado
    
    IS --Quando o regAssegura chera = 1 Sera registrado o Assegura para o objecto e retornar o id do assegurado na messagem
       -- Em outro caso nao sera registrado o assegurado e sera retornado o true na mensagem
        res PACK_TYPE.Resultado;
        
    BEGIN
        -- Buscar  pela identificacao do tipo do objecto
               
        INSERT INTO T_OBJECTO (OBJ_TOBJ_ID, OBJ_USER_ID)
                    VALUES (TIPO_OBJECTO, USER_ID) 
                       RETURNING OBJ_ID INTO res.resultado;
                    
        res.message := 'true';
        
        IF regAssegura = 1 THEN
          INSERT INTO T_ASSEGURA (ASE_CTT_ID, 
                                  ASE_OBJ_ID, 
                                  ASE_USER_ID)
                                  VALUES(ID_CONTRATO,
                                        res.resultado,
                                        USER_ID)
                                 RETURNING  ASE_ID INTO res.message;
          res.message := 'true;'||res.message;
                                                
        END IF;
        RETURN res;  
    END;
    
    
    
    
    
    
    
    FUNCTION GET_RESIDENCE
    (
      NAME_RESIDENCI IN CHARACTER VARYING,
      ID_USER NUMBER
    )
    RETURN NUMBER
    IS
      idResidencia INTEGER;
    BEGIN
    IF NAME_RESIDENCI IS NULL OR ID_USER IS NULL THEN RETURN NULL; END IF;
    -- a parir de um nome  da residencia ele vai procurar se ja existe,e se existir 
    --ele pega e retorna ,caso nao encontrar o nome da residencia ele regista e reorna o id daquela residencia
    
      -- Virificar se existe alguma zona com o nome fornecido no parametro
      SELECT COUNT(*) INTO idResidencia FROM T_OBJECTYPE  LL WHERE LL.OBJT_T_ID = 2 AND UPPER(LL.OBJT_DESC) = UPPER(NAME_RESIDENCI);
      IF idResidencia != 0 THEN
        -- Obter a identificacao do 
        SELECT LL.OBJT_ID INTO idResidencia 
           FROM T_OBJECTYPE  LL 
           WHERE LL.OBJT_T_ID = 2
              AND UPPER(LL.OBJT_DESC) = UPPER(NAME_RESIDENCI)
              AND ROWNUM <= 1;
        
        RETURN idResidencia;
      ELSE
        INSERT INTO T_OBJECTYPE(OBJT_T_ID,
                                OBJT_USER_ID,
                                OBJT_DESC)
                                    VALUES (2,
                                            ID_USER, 
                                            NAME_RESIDENCI)
                                RETURNING OBJT_ID INTO idResidencia;
        RETURN idResidencia;
      END IF;
      
    END;
    
    
    /*
    FUNCTION GET_IMPOSTO_ACTIVO RETURN NUMBER
    IS
      ID_IMPOSTO NUMBER;
    BEGIN
      SELECT IMP_ID INTO ID_IMPOSTO  
        FROM T_IMPOSTO
        WHERE IMP_STATE = 1;
    RETURN ID_IMPOSTO ;
    
    END;
    */
    
    -- Esse procedimento serve para adicionar novas coberturas ao contrato e ou ao segurado
    PROCEDURE addCoberturaContratoAssegura (idUser NUMBER,
                                            idContrato NUMBER,
                                            idAssegura NUMBER,
                                            expecificaoaCobertura TB_ARRAY_STRING)
   IS
       idCobertura NUMBER;
       lineSplitCobertura TB_ARRAY_STRING;
       taxa FLOAT;
       valor FLOAT;
       premio FLOAT;
       expecificacao FLOAT;
       detalhes VARCHAR(500);
   BEGIN 
       FOR i IN 1 .. expecificaoaCobertura.COUNT LOOP
           lineSplitCobertura := PACK_LIB.SPLITALL(expecificaoaCobertura(i), ';');
           idCobertura := lineSplitCobertura(1);
           valor := lineSplitCobertura(2);
           taxa := lineSplitCobertura(3);
           premio := lineSplitCobertura(4);
           detalhes := NULL;
           
           -- Se informar o detalhes entao registra o detalhe
           IF lineSplitCobertura.COUNT = 5 THEN detalhes := lineSplitCobertura(5); END IF;
           INSERT INTO T_COBERTURASEGURADO(COBREASE_COBRE_ID,
                                           COBREASE_CTT_ID,
                                           COBREASE_ASE_ID,
                                           COBREASE_USER_ID,
                                           COBREASE_VALOR,
                                           COBREASE_TAXA,
                                           COBREASE_PREMIO,
                                           COBREASE_DETALHES)
                                           VALUES(idCobertura,
                                                  idContrato,
                                                  idAssegura,
                                                  idUser,
                                                  valor,
                                                  taxa,
                                                  premio,
                                                  detalhes);
       END LOOP;
   END;
   
   
    -- Registrar um novo valor do atributo 
    -- Se nao encotrar o atributo ira registralo por padrao
    FUNCTION regObjVall(idUser NUMBER, attributVall VARCHAR2, attributeName VARCHAR2, super NUMBER, classTypeId NUMBER, idObjecto NUMBER, idContrato NUMBER) RETURN NUMBER
    IS
       clasAttribute T_OBJCLASSATTRIBUTE%ROWTYPE := getAttributeClass(idUser, attributeName, classTypeId, 0, 1);
       idUltimoRge NUMBER := NULL;
       tt NUMBER;
    BEGIN
       SELECT COUNT(*) INTO tt
          FROM T_OBJECTVALUE OB
          WHERE OB.OBJVALL_CLASSATB_ID = clasAttribute.CLASSATB_ID
            AND OB.OBJVALL_OBJ_ID = idObjecto
            AND OB.OBJVALL_STATE = 1
            AND OB.OBJVALL_VALUE = attributVall;
            
        IF tt = 0  THEN
           -- se esse objecto ja teve esse atributo entao inabilitar o atigo para poder atualizar
           UPDATE T_OBJECTVALUE  OB
             SET OB.OBJVALL_STATE  = 0 
             WHERE OB.OBJVALL_CLASSATB_ID = clasAttribute.CLASSATB_ID
                AND OB.OBJVALL_OBJ_ID = idObjecto
                AND OB.OBJVALL_STATE = 1;
                
             IF attributVall IS NOT NULL THEN
               -- Criar o valor desse atributo para o objecto
                INSERT INTO T_OBJECTVALUE(OBJVALL_CLASSATB_ID,
                                          OBJVALL_OBJ_ID,
                                          OBJVALL_USER_ID,
                                          OBJVALL_VALUE,
                                          OBJVALL_CTT_ID,
                                          OBJVALL_OBJVALL_ID)
                                          VALUES(clasAttribute.CLASSATB_ID,
                                                 idObjecto,
                                                 idUser,
                                                 attributVall,
                                                 idContrato,
                                                 super)
                      RETURNING OBJVALL_ID INTO idUltimoRge;
             END IF;
        ELSE
           -- Obter o identificador do objecto
           SELECT OB.OBJVALL_ID  INTO idUltimoRge
           FROM T_OBJECTVALUE OB
           WHERE OB.OBJVALL_CLASSATB_ID = clasAttribute.CLASSATB_ID
              AND OB.OBJVALL_OBJ_ID = idObjecto
              AND OB.OBJVALL_STATE = 1
              AND OB.OBJVALL_VALUE = attributVall
              AND ROWNUM <= 1;
        END IF;
        
      RETURN idUltimoRge;
    END;
    
    -- Registrar um novo attributo para a classe do objecto
    -- tipos dos atributos 0 - TEXT | 1 - VARCHAR | 2 - NUMBER | 3 - FLOAT | 4 - DATE | 5 - TIMESTAMP
    FUNCTION getAttributeClass(idUser NUMBER, nameAttribute VARCHAR2, classAttribute NUMBER, typeAttribute NUMBER, nullable NUMBER) RETURN T_OBJCLASSATTRIBUTE%ROWTYPE
    IS
       TYPE tpList IS TABLE OF  T_OBJCLASSATTRIBUTE%ROWTYPE;
       rowLinha T_OBJCLASSATTRIBUTE%ROWTYPE;
       lista tpList;
    BEGIN
       -- Verificara a existencia do atributo
       SELECT * BULK COLLECT INTO  lista
          FROM T_OBJCLASSATTRIBUTE ATT
            WHERE ATT.CLASSATB_NAME = nameAttribute
            AND ATT.CLASSATB_CLASS_ID = classAttribute;
      
       -- Quando nao exitir o atribute emtao criar
       IF lista.count = 0 THEN
          lista.extend;
          INSERT INTO T_OBJCLASSATTRIBUTE(CLASSATB_CLASS_ID,
                                         CLASSATB_USER_ID,
                                         CLASSATB_NAME,
                                         CLASSATB_TYPE)
                                         VALUES(classAttribute,
                                                idUser,
                                                nameAttribute,
                                                typeAttribute)
               RETURNING CLASSATB_CLASS_ID, CLASSATB_ID, CLASSATB_TYPE 
                  INTO rowLinha.CLASSATB_CLASS_ID, rowLinha.CLASSATB_ID, rowLinha.CLASSATB_TYPE
                ;
          lista(1) := rowLinha;
      END IF;
      
      RETURN lista(1);
    END;
    
    
    PROCEDURE regObjectValues (idUser NUMBER, idObject NUMBER, idContrato NUMBER, typeClass NUMBER, listValues TB_OBJECT_VALUES)
    IS
       idObjectValues NUMBER;
    BEGIN
       FOR I IN 1..listValues.count LOOP
          -- Reistrar o valor para o objecto
          idObjectValues := regObjVall(idUser, listValues(i).objValue, listValues(i).objName, listValues(i).objSupe,  typeClass, idObject, idContrato);
       END LOOP;
    END;
    
    FUNCTION loadObjectByAttribute (attributeName VARCHAR2, valueObject VARCHAR2, idClassObject NUMBER) RETURN PACK_TYPE.mapaValues
    IS
       TYPE ListNumber IS TABLE OF NUMBER;
       lista ListNumber := ListNumber();
       listPar PACK_TYPE.mapaValues;
    BEGIN
        -- Efectuar uma busca para carregar o objecto da classe que possui o id com o valor fornecido para o atributo fornecido
        SELECT 
            OV."ID OBJECTO" BULK COLLECT INTO lista
           FROM MVER_OBJECT_VALUES OV
           WHERE OV.ATRIBUTO = attributeName
              AND OV.VALUE = valueObject
              AND OV.CLASSE = idClassObject;
              
        listPar('OBJ.*') := '-1';
        -- Se encontrar ao menos um objecto entao carregar todos os valores do mesmo obecto
        IF lista.COUNT  = 1 THEN
        
          -- 0 | - TEXT | 1 - VARCHAR | 2 - NUMBER | 3 - FLOAT | 4 - DATE | 5 - TIMESTAMP
          -- O OBJ.* e o valor que contem o id do objecto
          listPar('OBJ.*') := lista(1);
          FOR OV IN (SELECT *
                       FROM MVER_OBJECT_VALUES OV
                       WHERE OV."ID OBJECTO" = lista(1))
          LOOP
             listPar(OV.ATRIBUTO) := OV."VALUE";
          END LOOP;
        END IF;
        
        RETURN listPar;
    END;
    
    FUNCTION loadObjectById (idObject NUMBER, idContrato NUMBER) RETURN TB_OBJECT_VALUES
    IS
       resValue VARCHAR2(4000);
       objectValues TB_OBJECT_VALUES := TB_OBJECT_VALUES();
       nameClass VARCHAR2(100);
    BEGIN
      -- carregar os dados do objecto para o contrato e para os objectos  do contrato
       FOR VV IN (SELECT *
                    FROM MVER_OBJECT_VALUES VV
                    WHERE 'true' = (CASE 
                                  WHEN idObject IS NOT NULL AND VV."ID OBJECTO"||'' = idObject||'' THEN 'true'
                                  WHEN idContrato IS NOT NULL AND VV."ID CONTRATO"||'' = idContrato||'' THEN 'true'
                                  ELSE 'false'
                               END))
       LOOP
          nameClass := VV."NOME CLASSE";
          objectValues.EXTEND;
          resValue := VV."VALUE";
          
          -- Se o valor estiver sendo referenciado da ourtra entiade entao efectuar a buscao do real valor na entidade referenciada
          IF VV."TABLE ORIGIN" IS NOT NULL 
             AND VV."TABLE ID" IS NOT NULL
             AND VV."TABLE VALUE" IS NOT NULL
          THEN 
             resValue := PACK_LIB.GETVALL(VV."TABLE ORIGIN", VV."TABLE ID", VV."TABLE VALUE", resValue, '=', 1);
          END IF;
          
          objectValues(objectValues.COUNT) := TP_OBJECT_VALUES (VV."SUPER", VV.ATRIBUTO, resValue);
       END LOOP;
       objectValues.EXTEND;
       objectValues(objectValues.COUNT) := TP_OBJECT_VALUES (null, 'OBJ.CLASS.*', nameClass);
       
       RETURN objectValues;
    END;
    
    
    FUNCTION GET_TAXA_DIA (dataTaxa DATE, idMoeda NUMBER) RETURN NUMBER
    IS
       idTaxa NUMBER;
    BEGIN
       FOR TA IN (SELECT * 
                     FROM (SELECT * 
                               FROM T_TAXA TA
                               WHERE TA.TX_MOE_ID = 149
                                 AND TA.TX_DTREG <= dataTaxa
                                 AND TA.TX_MOE_BASE = idMoeda
                                 AND TA.TX_STATE = 1
                               ORDER BY TA.TX_DTREG DESC)
                    WHERE ROWNUM <=1)
       LOOP
          idTaxa := TA.TX_ID;
          EXIT;
       END LOOP;
       RETURN idTaxa;
    END;
    
    
    FUNCTION getObjectTypeValue(idObject NUMBER) RETURN CHARACTER VARYING
    IS 
        objectValue T_OBJECTYPE.OBJT_DESC%TYPE;
    BEGIN
       SELECT O.OBJT_DESC INTO objectValue
          FROM T_OBJECTYPE O
          WHERE O.OBJT_ID = idObject;
          
       RETURN objectValue;
          
       EXCEPTION 
          WHEN NO_DATA_FOUND THEN
             RETURN NULL;
             
    END;
    
    FUNCTION getValueObject(idObject NUMBER, idContrato NUMBER, nomeAtributo CHARACTER VARYING) RETURN CHARACTER VARYING
    IS
       vall CHARACTER VARYING(4000);
    BEGIN
       IF (idObject IS NULL AND idContrato IS NULL )
          OR (idObject IS NOT NULL AND idContrato IS NOT NULL ) THEN
          RETURN NULL;
       END IF;
       
       FOR OV IN (SELECT *
                    FROM (SELECT *
                            FROM T_OBJECTVALUE OV
                               INNER JOIN T_OBJCLASSATTRIBUTE ATB ON ATB.CLASSATB_ID = OV.OBJVALL_CLASSATB_ID
                            WHERE OV.OBJVALL_CTT_ID = idContrato
                               AND OV.OBJVALL_STATE = 1
                               AND ATB.CLASSATB_NAME = nomeAtributo
                            ORDER BY OV.OBJVALL_DTREG DESC) OV
                    WHERE ROWNUM <= 1)
       LOOP
          vall := OV.OBJVALL_VALUE;
       END LOOP;
       
       RETURN vall;
    END;
    


END PACK_REGRAS;