drop FUNCTION  rule.funct_aplicar_multa ();
CREATE or REPLACE FUNCTION rule.funct_aplicar_multa () RETURNS SETOF credial.credito
	LANGUAGE plpgsql
AS $$


    DECLARE

      /*
        RESP                TB_SIMULACAO  := TB_SIMULACAO();
        POS                 NUMBER        := 0;
        NUM_SEMANAS         NUMBER        := 0;
        RESTO_DIVISAO       NUMBER        := 0;
        SIMULARVALOR_SEGURO BINARY_DOUBLE := 0;


    taxaSimula          BINARY_DOUBLE := 0;
    periodoSimula       INTEGER       := 0;
    capiatalSimula      BINARY_DOUBLE := 0;
      */

      numPeriodo INTEGER DEFAULT 0;
      numSemanas INTEGER DEFAULT 0;
      restoDivisao INTEGER DEFAULT 0;
      taxaSimulacao DOUBLE PRECISION DEFAULT .0;
      capitalSimulacao DOUBLE PRECISION DEFAULT .0;
      periodoSimula DOUBLE PRECISION DEFAULT .0;

      vTaxaSup credial.taxa;
      vTaxaInf credial.taxa;

      i RECORD;

      nAcumularPenalidade DOUBLE PRECISION DEFAULT 0;
      diferencaDatas      INTEGER DEFAULT 0;
      simulaValorSeguro credial.seguro;

    BEGIN
      -- OS SIMULARVALORES >31 CORESPONDE A MESES
      -- OS SIMULARVALORES <= 30 CORREESPONDEM A SEMANAS
      -- UMA SEMANA CORESPONDE A 7 DIA E CORESPONDE A UM PERIODO
      -- DUAS SEMANAS CORESPONDE A 15 diferencaDatas 2 PERIODOS
      -- 3 SEMANS CORESPONDE A 21 diferencaDatas 3 PERIODOS
      -- 4 SEMANS CORESPONDE A 30 diferencaDatas 4 PERIODO
      -- OS SIMULARVALORES > 30 A MESES 31 CORESPINDE A 1 MES E NESTE CASO UM PERIODO
      -- 60 MESES 2 PERIODSO, 90  3 MESES 3 PERIODOS, 120 diferencaDatas 4 MESES 4 PERIODOS, ECT

      -- CURSOR PARA PERCORER AS SELECOES DOS CREDITOS COM PENALIDADE DO INICIO ATE AO FIN

      SELECT * into I
        from credial.credito ce
          INNER JOIN credial.taxa tx on ce.credi_taxa_id = tx.taxa_id
        limit 0;


      FOR I IN (
        SELECT *
          from credial.credito ce
            INNER JOIN credial.taxa tx ON ce.credi_taxa_id = tx.taxa_id
          where ce.credi_state = 1
            and ce.credi_dtfinalizar < now()::date
            and ce.credi_valuepago < ce.credi_valuecredito
      ) LOOP

        nAcumularPenalidade := I.credi_penalidade;
        diferencaDatas := now()::date - i.credi_dtrge::date;

        IF diferencaDatas < 30 THEN  -- caso for semana
          numPeriodo := 1;
          numSemanas := 30;
        ELSE
          numSemanas := 30;
          numPeriodo := trunc(diferencaDatas/numSemanas);
          restoDivisao := mod(diferencaDatas, numSemanas);
        END IF;

        IF restoDivisao >= 1 THEN
          numPeriodo := numPeriodo +1;
        ELSIF restoDivisao = 0 THEN
          numPeriodo := numPeriodo;
        END IF;

        IF numPeriodo >= 4 AND numSemanas = 0 THEN
          numPeriodo := 4;
        ELSIF numPeriodo >= 2 and numSemanas = 30 then
          simulaValorSeguro := rule.get_seguro_activo();
        END IF;

        --BUSCAR AS TAXAS SUPERIORES E INFERIORES

        vTaxaInf := rule.get_taxa_periodo_inferior(diferencaDatas, i.taxa_obj_tipocredito);
        vTaxaSup := rule.get_taxa_periodo_superior(diferencaDatas, i.taxa_obj_tipocredito);

        If vTaxaSup.taxa_id is not null then -- QUANDO HOUVER TAXA SUPERIOR

          if vTaxaSup.taxa_value >= 1 then

            taxaSimulacao := vTaxaSup.taxa_value;
            periodoSimula := numPeriodo;
            capitalSimulacao := i.credi_valuecredito;

            DECLARE
              nTaegSup DOUBLE PRECISION DEFAULT 0;
              nTaegInf DOUBLE PRECISION DEFAULT 0;
              nDiaMais DOUBLE PRECISION DEFAULT 0;
              nTaegDiferenca DOUBLE PRECISION DEFAULT 0;
              xDiario DOUBLE PRECISION DEFAULT 0;

              taegSemDescontoSimula DOUBLE PRECISION default 0;
              taegComDescontoSimula DOUBLE PRECISION default 0;
              descontoSimula DOUBLE PRECISION DEFAULT  0;
              descontoSimulaCorecaoTotal DOUBLE PRECISION DEFAULT 0;
              taegSimula DOUBLE PRECISION DEFAULT 0;
              totalPagarSimula DOUBLE PRECISION DEFAULT 0;
              xPenalidadeEfectiva DOUBLE PRECISION DEFAULT 0;

            BEGIN

               -- X1 CALCULO DE TAEG SUPERIOR
              nTaegSup := i.credi_valuecredito * (vTaxaSup.taxa_value / 100);

              -- X2 CALCULO DE TAEG INFERIOR
              nTaegInf := i.credi_valuecredito * (vTaxaInf.taxa_value / 100);

              -- D1 - D2 INF diferencaDatas DO PERIODOP MENOS O PERIODO DA TAGE INFERIOR
              nDiaMais := diferencaDatas - vTaxaSup.taxa_periodo;

              -- X2 - X1 DIFERENCA ENTRE A TAEG SUPERIRO E INFERIOR
              nTaegDiferenca := nTaegSup - nTaegInf;

              -- DIARIO = (X1 - X2)/DLIMSUP - D2 LIMINF
              if (vTaxaSup.taxa_periodo - vTaxaInf.taxa_periodo = 0)
                or (nTaegSup - nTaegInf = 0) then
                xDiario := 0;
              ELSE
                xDiario := (nTaegSup-nTaegInf) / (vTaxaSup.taxa_periodo - vTaxaInf.taxa_periodo);
              END IF;

              taegSemDescontoSimula := (nTaegInf + (xDiario * nDiaMais));

              taegSimula := taegSemDescontoSimula;
              totalPagarSimula := i.credi_valuecredito + taegSimula + simulaValorSeguro.seg_value;
              -- xPenalidadeEfectiva := totalPagarSimula - i.CERDI_TOTALAPAGAR;
              xPenalidadeEfectiva := totalPagarSimula - i.credi_valuecredito;

              PERFORM rule.funct_update_penalidade(xPenalidadeEfectiva, i.credi_id::integer, i.credi_dos_nif);

            END;
          END IF;

        END IF;

      END LOOP;
      RETURN '(true,sucess)'::credial.result;
    END;


$$
