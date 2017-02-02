CREATE or REPLACE FUNCTION report.funct_rep_cobranca ("idUser" character varying, "idAgencia" integer, "dataInicio" date, "dataFim" date, filter json) RETURNS TABLE("ID" integer, "NIF" character varying, "NAME" character varying, "SURNAME" character varying, "VALOR REEMBOLSO" character varying, "NUM DOCUMENTO REAL" character varying, "NUM DOCUMENTO PREVISTO" character varying, "DATA DOCUMENTO REAL" character varying, "DATA DOCUMENTO PREVISTO" character varying)
	LANGUAGE plpgsql
AS $$
    DECLARE

      idTipoCreditoReport integer default filter->>'tipoCredito';
      idBancoReport integer default filter->> 'banco';
      anoSubtrairReport integer DEFAULT  filter->>'anoSub';
      idAgenciaReport integer DEFAULT  filter->>'agencia';
 
      
      
      
      -- criar data dos anos antigos
      vInterval CHARACTER VARYING DEFAULT anoSubtrairReport||' year ';
      vDataInicio DATE DEFAULT "dataInicio" - (vInterval::INTERVAL);
      vDataFim DATE DEFAULT "dataFim" - (vInterval::INTERVAL);

      sumValorCreditoData FLOAT DEFAULT 0;
      sumDividaData FLOAT DEFAULT  0;
      sumTaegData FLOAT DEFAULT  0;

      I RECORD;

    BEGIN

      -- Essa funcao serve para listar todas as cobrancas que foram sendo feita em um intervalo de tempo
      -- Carregar todos as cobranca no intervalo indicado  null banco indicado null tipo do credito indicado
      -- Atenção que as cobranças correspondem ao pagamentos feito
      -- No final deve ser somado o valor de totas essas cobrancas feitas
      -- Quando a agentia ou o tipo do credito equals -1 then siginifica que se pretende carregar todas as informacoes

      FOR I IN (SELECT
                  pay.paga_id AS id,
                  cd.credi_dos_nif AS nif,
                  dos.dos_name AS "name",
                  dos.dos_surname AS surname ,
                  b.banco_sigla AS sigla,
                  pay.paga_reembolso AS valorReembolso,
                  pay.paga_numdocumentopagamentoreal AS numDocumentoPagamentoReal,
                  pay.paga_dtdocumentopagamentoreal AS dataDocumentoPagamentoReal,
                  pay.paga_numdocumentopagamento AS numDocumentoPagamentoPrevisao,
                  pay.paga_dtdocumentopagamento AS dataDocumentoPagamentoPrevisto,

                  pay.paga_banco_idreal as idBancoReal,
                  tx.taxa_obj_tipocredito as tipoCredito,
                  pay.paga_age_id AS idAgencia,
                  pay.paga_dtreg

                FROM credial.pagamento pay

                  INNER JOIN credial.banco B ON pay.paga_banco_id  =  b.banco_id
                  INNER JOIN credial.credito cd ON pay.PAGA_CREDI_ID = cd.credi_id
                  INNER JOIN credial.dossiercliente dos ON cd.CREDI_DOS_NIF = dos.dos_nif
                  INNER JOIN credial.taxa tx ON cd.credi_taxa_id = tx.taxa_id

                WHERE pay.paga_state = 0

                  AND pay.paga_dtdocumentopagamento BETWEEN "dataInicio" AND "dataFim"
                  AND (pay.paga_banco_idreal = idBancoReport OR idBancoReport is NULL)
                  AND (tx.taxa_obj_tipocredito = idTipoCreditoReport OR idTipoCreditoReport IS NULL)
                  AND (pay.paga_age_id = idAgenciaReport OR idAgenciaReport IS NULL)

                ORDER BY pay.paga_dtreg ASC
      ) LOOP

        "ID" := I.id;
        "NIF" :=  I.nif;
        "NAME" := I."name";
        "SURNAME" := I.surname;
        "VALOR REEMBOLSO" := I.valorReembolso;
        "NUM DOCUMENTO REAL" := I.numDocumentoPagamentoReal;
        "NUM DOCUMENTO PREVISTO" := I.numDocumentoPagamentoPrevisao;
        "DATA DOCUMENTO REAL" := I.dataDocumentoPagamentoReal;
        "DATA DOCUMENTO PREVISTO" := I.dataDocumentoPagamentoPrevisto;

        sumValorCreditoData := sumDividaData + I.valorReembolso;

        RETURN NEXT;

      END LOOP;

      -- Aplicar o valor do somatorio no resultado da seleção
      "ID" := NULL;
      "NIF":= 'TOTAL';
      "NAME" := 'ANO ATUAL';
      "SURNAME" := NULL;
      "VALOR REEMBOLSO" := sumValorCreditoData;
      "NUM DOCUMENTO REAL" := NULL;
      "NUM DOCUMENTO PREVISTO" := NULL;
      "DATA DOCUMENTO REAL" := NULL;
      "DATA DOCUMENTO PREVISTO" := NULL;

      RETURN NEXT;


      -- Quando for disponibilizado a diferenca do ano enta deves efetuar um somatorio de todas as cobrancas feita no
      -- intervalo indicado mais aplicando a diferenca exemplo
      -- SE FOR DE 10-11-2015 PARA 10-12-2015 COM DIFERENCA = 2
      -- ENTÃO SERA 10-11-2013 PARA 10-12-2013 DIFERENCA de 2 Anos

      -- Quando a agentia ou o tipo do credito equals -1 then siginifica que se pretende carregar todas as informacoes


      IF anoSubtrairReport >0 THEN

        sumValorCreditoData := 0;
        sumDividaData := 0;
        sumTaegData := 0;


        SELECT
          sum(pay.paga_reembolso) into sumValorCreditoData
        FROM credial.pagamento pay

          INNER JOIN credial.banco B ON pay.paga_banco_id  =  b.banco_id
          INNER JOIN credial.credito cd ON pay.PAGA_CREDI_ID = cd.credi_id
          INNER JOIN credial.dossiercliente dos ON cd.CREDI_DOS_NIF = dos.dos_nif
          INNER JOIN credial.taxa tx ON cd.credi_taxa_id = tx.taxa_id
        WHERE pay.paga_state = 0
              AND pay.paga_dtdocumentopagamento BETWEEN vDataInicio AND vDataFim
               AND (pay.paga_banco_idreal = idBancoReport OR idBancoReport is NULL)
               AND (tx.taxa_obj_tipocredito = idTipoCreditoReport OR idTipoCreditoReport IS NULL)
               AND (pay.paga_age_id = idAgenciaReport OR idAgenciaReport IS NULL)
          ;

        "VALOR REEMBOLSO" := sumValorCreditoData;
        "NAME" := anoSubtrairReport ||' ANO PASSADOS';

        RETURN NEXT;
      ELSE

        RETURN NEXT;
      END IF;
    END;
$$
