DROP FUNCTION get_cheque_randon ("idUser" character varying, idconta numeric, "idAgencia" numeric, "valorRequisicao" double precision);


CREATE OR REPLACE FUNCTION rule.get_cheque_randon ("idUser" character varying, idconta numeric, "idAgencia" numeric, "valorRequisicao" double precision) RETURNS credial.chequempresa
	LANGUAGE plpgsql
AS $$
  DECLARE
    numSequencia character varying;
    ram numeric;
    inicio character varying;
    fim character varying;
    id numeric;
    tt numeric default -1;
    ttCreditos numeric;
    ttChequesExpirados numeric;
    vCheque credial.chequempresa%ROWTYPE;
    vChequeAux credial.chequempresa%ROWTYPE;
    looper numeric default 0;
    ttDestribuido numeric;
    ttExistene numeric;
    saldoSuf numeric;
    valorAnterior double precision;
    totalValorRequisitado double precision; -- Corresponde a todos os valores que o utilizador requistou

  BEGIN
     --<ORACLE COD PL.SQL>
     -- 1º Destruir todas as atigas requisicoes feitas que ja estao expiradas independentemente do banco e da agencia
       --Carregar todas as requisicoees invalidas
      /*FOR d IN (SELECT *
                    FROM REQUISICAOCHEQUE d
                    WHERE d.REQCHEQ_USER_ID = userid
                         OR d.REQCHEQ_STATE = 0
                         OR d.REQCHEQ_DTLAST <= (SYSDATE - INTERVAL '15' MINUTE)
                          )
      LOOP
          -- Repor o valor virtual anteriormente requisitado de todas as requisicao
             -- Indepenetentemente do banco ou da agencia desde que estaja em um estado incalido
          UPDATE BANCO B
            SET B.BANCO_SALDOVIRTUAL = B.BANCO_SALDOVIRTUAL + d.REQCHEQ_VALOREQ
            WHERE B.BANCO_ID = d.REQCHEQ_BANCO_ID;
      END LOOP;*/
     --</ORACLE COD PL.SQL>

     --<ORACLE COD PL.SQL>
      /* -- Remover todas as requisicoes ja invalidas
        DELETE FROM REQUISICAOCHEQUE d
        WHERE d.REQCHEQ_USER_ID = userid
           OR d.REQCHEQ_STATE = 0
           OR d.REQCHEQ_DTLAST <= (SYSDATE - INTERVAL '15' MINUTE);
    */
    --</ORACLE COD PL.SQL>

    -- Verificar a existencia da sequecia desso bancoa para a aguencia

    select count(*) into tt
      from credial.chequempresa ch
      where ch.cheq_conta_id = idconta
        and ch.cheq_age_owner = "idAgencia"
        and ch.cheq_total > ch.cheq_distribuido
        and ch.cheq_state = 1;

    -- buscar o total de saldo disponivel no banco requistado
    select count(*) into saldoSuf
      from credial.banco bc
        INNER JOIN credial.conta ct on bc.banco_id = ct.conta_banco_id
      where bc.banco_saldo >= "valorRequisicao"
        and ct.conta_id = idconta;

    -- Caso existir na aguencia algum cheque para o banco entao
    -- VERIFICANDO SE EXISTE ALGUMA CARDINETA PARA DAR RESPOSTA A TAL REQUISICAO

    if tt != 0 and saldoSuf = 1 then
      -- Buscar a identificacao, a sequencia inicial e a sequencia final

      select * into vCheque
        from credial.chequempresa ch
          INNER JOIN credial.conta ct on ch.cheq_conta_id = ct.conta_id
          inner join credial.banco bc on ct.conta_banco_id = bc.banco_id
        where ct.conta_id = idconta
          and ch.cheq_age_owner = "idAgencia"
          and bc.banco_saldo >= "valorRequisicao"
          and ch.cheq_total > ch.cheq_distribuido
          and ch.cheq_state = 1;

      -- BEGIN PROXIMALING -- A proxima linha e pro causa da requiscisão do credito que deixou de ser aplicado
      tt := 0;
      -- END PROXIMALINHA

      numSequencia := SUBSTR(vChequeAux.cheq_sequencefim, 1, LENGTH(vChequeAux.cheq_sequencefim) - 3);

      /*-- Criando um ciclo para gerarm um numero de sequencia aletoria entre o inicio e o fim da sequencia
            tt := -1;

            WHILE tt != 0 AND looper < ttExistente LOOP

              -- Retirar um cheque au calhar do lote
              ram := dbms_random.value(inicio, fim + 1);

              -- Garatir que o valor gerado nao ultrapasse a mega final por causa de +1
                IF ram > TO_NUMBER(fim) THEN
                  ram := ram - 1;
                END IF;

                -- Formatar o valor gerado para 21 digitos
                numSequencia := TO_CHAR(ram || '', 'FM00000000000000000000000000000');

                -- Verificar se o cheque criado ja esta ou nao sendo usado
                SELECT COUNT(*) INTO ttCredito
                  FROM CERDITO c
                  WHERE c.CREDI_CHEQ_ID = id
                    AND c.CREDI_NUMCHEQUE = numSequencia;

                -- BEGIN PROXIMALING -- A proxima linha e pro causa da requiscisão do credito que deixou de ser aplicado
                tt := ttCredito;
                -- END PROXIMALINHA

                /*IF tt = 0 THEN
                  SELECT COUNT(*)
                    INTO tt
                    FROM REQUISICAOCHEQUE d
                    WHERE d.REQCHEQ_CODIGO = numSequencia
                  ;
                END IF;*/
                -- Se encontar alngum entao recorrer  novamente o looper
            /*IF tt != 0 AND ttCredito != 0 THEN tt := -1; END IF;
                looper := looper + 1; -- Incrementar a volta
              END LOOP;
              */
              -- Terminado o ciclo se o tt for 0 siginifica que o numero do cheque criado nao existe nos credito ne foi requisitado pro nehum utilizador
              IF tt = 0 THEN
                /*-- Criar a requisicao do cheque que foi pedido
                INSERT INTO REQUISICAOCHEQUE (REQCHEQ_USER_ID,
                                              REQCHEQ_CODIGO,
                                              REQCHEQ_CHEQ_ID,
                                              REQCHEQ_BANCO_ID,
                                              REQCHEQ_AGE_ID,
                                              REQCHEQ_VALOREQ
                                              )VALUES( userid,
                                                       numSequencia,
                                                       id,
                                                       idBanco,
                                                       idAgencia,
                                                       valorRequisicao);
                                                       */
                -- tt recebe 2 siginifica que cosegui-se criar o cheque para o utilizador
                tt := 2;
              END IF;
      ELSE -- Se nao existir nessa agencia nennuma cardineta para dar resposta a essa requisicao entao invalidar o pedido
          res.idCheque := -1;
          res.numSequencia := CASE WHEN saldoSuf = 0 THEN 'SALDO' ELSE  'CHEQUE' END;
          RETURN res;
      END IF;

      -- CASO encontre o total
      IF tt = 2 THEN
        res.idCheque := id;
        res.numSequencia := numSequencia;
        RETURN res;
      /*ELSE
        -- Nao consegue criar o cheque verificar a quantidade do cheque dessa cardineta que esta reservado temporariamente
        SELECT COUNT(*) INTO tt
          FROM REQUISICAOCHEQUE d
          WHERE d.REQCHEQ_CHEQ_ID = id
            AND (d.REQCHEQ_STATE = 0
            OR d.REQCHEQ_DTLAST <= (SYSDATE - INTERVAL '15' MINUTE));

        -- O total destribuido = total destribudo realmete mais a quantidade do cheque reservado
        ttDestribuido := ttDestribuido + tt;
         -- Ainda existe cheques por destribuir nessa secao voltar a reavaliar o pedido do cheque
        IF ttDestribuido < ttExistente THEN
            RETURN PFUNC_GET_CHEQUE_RANDOM(userid,
                                           idBanco,
                                           idAgencia,
                                           valorRequisicao);
        END IF;*/
        */
    end if;
    return vCheque;
    
  END;
$$
