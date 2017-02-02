-- DROP FUNCTION funct_load_banco_simulacao ("idUser" character varying, "idAgencia" numeric, "valorRequisicao" double precision);

CREATE OR REPLACE FUNCTION funct_load_banco_simulacao(
  "idUser" character varying,
  "idAgencia" numeric,
  "valorRequisicao" double precision
) RETURNS TABLE (
  "ID" numeric,
  "NAME" character varying,
  "SIGLA" character varying,
  "STATE" INTEGER,
  "MESSAGE" CHARACTER VARYING,
  "VARIABLE_DIGITS" SMALLINT
)
	LANGUAGE plpgsql
AS $$

  DECLARE
    i RECORD;
    tt integer;
    nameConta CHARACTER VARYING;
  BEGIN

    -- Apresentar os banco disponivel para a agencia
     FOR i iN (
      SELECT *
        FROM  credial.chequempresa ch
          INNER JOIN credial.conta ct on ch.cheq_conta_id = ct.conta_id
          INNER JOIN credial.banco b on ct.conta_banco_id = b.banco_id
        WHERE ch.cheq_age_owner = "idAgencia"
          AND ch.cheq_state = 1
          AND b.banco_saldo >= "valorRequisicao"
        ORDER BY banco_sigla
    )
    LOOP

       nameConta := i.conta_desc;
       "ID" := i.conta_id;
       "NAME" := i.banco_name;
       "SIGLA" := i.banco_sigla ;
       "STATE" := 1;
       "MESSAGE" := 'Disponivel';
       "VARIABLE_DIGITS" := i.banco_variabledigitscheques;
       RETURN NEXT;

    END LOOP;

    "VARIABLE_DIGITS" := NULL;
    -- Apresentar os bacos nao disponivel com cheque e saldo
    FOR i IN (
      SELECT *
        FROM credial.banco bc
        WHERE bc.banco_id not in (
           SELECT b.banco_id
            FROM  credial.chequempresa ch
              INNER JOIN credial.conta ct on ch.cheq_conta_id = ct.conta_id
              INNER JOIN credial.banco b on ct.conta_banco_id = b.banco_id
            WHERE ch.cheq_age_owner = "idAgencia"
              AND ch.cheq_state = 1
              AND b.banco_saldo >= "valorRequisicao"
        )
        ORDER BY bc.banco_sigla asc

    ) LOOP

      "ID" := i.banco_id*(-1);
      "NAME" := i.banco_name;
      "SIGLA" := i.banco_sigla;
      "STATE" := 0;


      --Verificar so o baco tem cheque para a agencia
      SELECT count(*) into tt
        from chequempresa ch
          INNER JOIN  credial.conta ct  ON ch.cheq_conta_id = ct.conta_id
          where ct.conta_banco_id = i.banco_id;

      "MESSAGE" := message('no-available');

      IF tt = 0 then
        "MESSAGE" := message('no-cheque-available');
      ELSIF i.banco_saldo < "valorRequisicao" THEN
        "MESSAGE" := message('no-saldo-available');
      END IF;

      RETURN NEXT;

    END LOOP;
  END;
$$;



