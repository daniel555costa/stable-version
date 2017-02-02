DROP FUNCTION report.funct_rep_client_crescimento_homologo ("idUser" character varying, "idAgencia" integer, "dataInicio" date, "dataFim" date, filter json);
CREATE or REPLACE FUNCTION report.funct_rep_client_crescimento_homologo ("idUser" character varying, "idAgencia" integer, "dataInicio" date, "dataFim" date, filter json) RETURNS TABLE("NIF" character varying, "CLIENT NAME" character varying, "CLIENT SURNAME" character varying, "LOCALIDADE" CHARACTER VARYING, "QUANTIDADE ANO" integer, "QUANTIDADE PASSADO" integer, "DIFERENCA" character varying)
	LANGUAGE plpgsql
AS $$
  DECLARE

    anoSubtrairReport integer DEFAULT filter->>'anoSub';
    idLocalidadeReport  integer DEFAULT filter ->>'localidade';
    idAgenciaReport integer DEFAULT filter->>'agencia'; 
    idTipoCreditoReport integer DEFAULT filter->>'tipoCredito';


    -- criar data dos anos antigos
    vInterval CHARACTER VARYING DEFAULT anoSubtrairReport||' year ';
    vDataInicio DATE DEFAULT "dataInicio" - (vInterval::INTERVAL);
    vDataFim DATE DEFAULT "dataFim" - (vInterval::INTERVAL);

    totalCreditoData NUMERIC;
    totalCreditoOther NUMERIC;
    diferencaData NUMERIC;

    vSomatorio RECORD;
    I RECORD;

  BEGIN

    /*
    SELECT
      CAST(DSS.DOS_NIF AS VARCHAR(15)) AS NIF,
      H.HISDOS_TRAB_ID AS LOCALIDADE,
      CAST('' AS VARCHAR2(126)) AS "VALOR DATA", --
      CAST('' AS VARCHAR2(126)) AS "VALOR ANTIGO", --
      CAST('' AS VARCHAR2(126)) AS "DIFIFERENCA VALOR"  -- Diferenca data
    FROM DOSSIERCLIENTE DSS
      INNER JOIN HISTORICOCLIENTE H ON DSS.DOS_NIF = H.HISDOS_DOS_NIF
      --INNER JOIN VER_LOCALIDADE VL ON H.HISDOS_TRAB_ID = VL.ID
    WHERE H.HISDOS_ESTADO = 1


     */

    -- CREATE STRUCTURE TO vSomatorio
    SELECT
      NULL::CHARACTER VARYING AS "NIF",
      NULL::INTEGER AS "LACALIDADE",
      0::INTEGER "VALOR DATA",
      0::INTEGER AS "VALOR ANTIGO",
      0::INTEGER AS "DIFERENCA VALOR"
      INTO vSomatorio;

    FOR  I IN (
      SELECT
          DSS.DOS_NIF AS "NIF",
          loc.local_desig AS "LOCALIDADE",
          DSS.dos_name AS "NAME",
          DSS.dos_surname AS "SURNAME",

          -- Contabilizar o total dos credito para a data fornecida
          -- Quando a agencia ou tipo do creddito equal -1 then siginifica que se pretende carregar todas as informacoes
          COUNT(
            CASE
              WHEN ce.credi_dtinicio BETWEEN "dataInicio" AND "dataFim" then true
              ELSE NULL
            END
          ) AS "TOTAL ANO",

          -- Buscar o total dos credito para a data forncida antiga
          COUNT(
            CASE
              WHEN ce.credi_dtinicio BETWEEN  vDataInicio AND vDataFim THEN TRUE
              ELSE NULL
            END
          ) AS "TOTAL PASSADO"
        FROM credial.dossiercliente dss
          INNER JOIN credial.historicocliente H ON DSS.DOS_NIF = H.HISDOS_DOS_NIF
          INNER JOIN credial.localidade loc ON h.hisdos_local_id = loc.local_id
          INNER JOIN credito ce on dss.dos_nif = ce.credi_dos_nif
          INNER JOIN taxa tx ON ce.credi_taxa_id = tx.taxa_id
        WHERE H.hisdos_state = 1
          AND (idAgenciaReport =  ce.credi_age_id OR idAgenciaReport IS NULL)
          AND (idTipoCreditoReport = tx.taxa_obj_tipocredito OR idTipoCreditoReport IS NULL)
          AND (h.hisdos_local_id = idLocalidadeReport OR idLocalidadeReport is NULL)
        GROUP BY "NIF", "LOCALIDADE", "NAME", "SURNAME"
    )LOOP

      diferencaData := I."TOTAL ANO" - I."TOTAL PASSADO";

      "QUANTIDADE ANO" := I."TOTAL ANO";
      "QUANTIDADE PASSADO" := I."TOTAL PASSADO";
      "DIFERENCA" := diferencaData;
      "CLIENT NAME" := I."NAME";
      "CLIENT SURNAME" := I."SURNAME";

      -- Apresentar somente os que compram mais creditos nesse ano do que no ano passado
      IF diferencaData > 0 THEN

        vSomatorio."VALOR DATA" := vSomatorio."VALOR DATA" + I."TOTAL ANO";
        vSomatorio."VALOR ANTIGO" := vSomatorio."VALOR ANTIGO" + I."TOTAL PASSADO";
        vSomatorio."DIFERENCA VALOR" := vSomatorio."DIFERENCA VALOR" + diferencaData;
        "NIF" := I."NIF";
        "LOCALIDADE" := I."LOCALIDADE";

        RETURN NEXT;
      END IF;
    END LOOP;

    "NIF" := 'TOTAL';
    "LOCALIDADE" := NULL;
    "QUANTIDADE ANO" := vSomatorio."VALOR DATA";
    "QUANTIDADE PASSADO" := vSomatorio."VALOR ANTIGO";
    "CLIENT NAME" := NULL;
    "CLIENT SURNAME" := NULL;
    "DIFERENCA" := vSomatorio."DIFERENCA VALOR";
    RETURN  NEXT;
  END;
$$
