CREATE OR REPLACE FUNCTION credial.funct_efetuar_pagamento ("idAgencia" numeric, "idUser" character varying, "idPagamento" numeric, "documentoPagamentoReal" character varying, "idBancoReal" numeric, "tipoPagamento" character varying, "valorPrestacao" double precision, "dataDocumentoPagamento" date) RETURNS result
	LANGUAGE plpgsql
AS $$

  DECLARE
    -- Essa funcao serve para fazer a atualizado
    -- S Semelhante | D Diferente | F Faseado

    vPagamento pagamento;
    vCredito credito;
    estadoPagamento numeric;
    res result;

    resPay result;
    -- Para pagamento tenho

    valorPagar double precision;
    documentoUsar character varying(30);
    bancoUsar numeric;
    porTranche numeric DEFAULT 0;

    valorFazeado numeric;
    valido BOOLEAN DEFAULT FALSE;
    diferencaValor double precision;

    ttPagaOpen numeric; -- total de pagamento que resta por pagar
    dataDocumentoUsar DATE DEFAULT NULL;

    libele  character varying;
  BEGIN
    res.result := FALSE ;

    -- RETURN ('(false,valorSomatorio:)')::result;

    select * into vPagamento
      from pagamento pa
      where pa.paga_id = "idPagamento";

    select * into vCredito
      from credito ce
      where ce.credi_id = vPagamento.paga_credi_id;

    if vPagamento.paga_partrance = 1
      and ("tipoPagamento" = 'S' or "tipoPagamento" = 'D')
    then
      res.message := message('PAY-NOT-EFETUADO');
      return res;
    end if;

    -- Caso o pagamento aindo nao foi pago entao
    if vPagamento.paga_state = 1 then

      -- Quando for pagamento Semelhante
        -- Todos os dados meten-se o mesmo
      if "tipoPagamento" = 'S' then
        valorPagar = vPagamento.paga_reembolso;
        documentoUsar := vPagamento.paga_numdocumentopagamento;
        bancoUsar := vPagamento.paga_banco_id;
        libele := 'Amortizacao do credito do dossier nº '||vCredito.credi_numcredito||' com seguinte documento '||documentoUsar;
        dataDocumentoUsar := "dataDocumentoPagamento";
        valido := true ;

      -- Quando for pagamento diferente nao fazeado
        -- Valor matem o mesmmo valor que reembolso o documento e o banco e que pode ser alterado
      elseif  "tipoPagamento" = 'D' then
        valorPagar := vPagamento.paga_reembolso;
        documentoUsar := "documentoPagamentoReal";
        bancoUsar := "idBancoReal";
        libele := 'Amortizacao do credito do dossier nº'||vCredito.credi_numcredito||' com seguinte documento '|| documentoUsar;
        valido := TRUE;

      -- Quando for pagamento diferente fazeado
        -- o valor pagar muda  o documento e o banco e que pode ser alterado
      elseif "tipoPagamento" = 'F' then

        porTranche := 1;
        valorPagar := "valorPrestacao";
        documentoUsar := "documentoPagamentoReal";
        bancoUsar := "idBancoReal";


        libele := 'Amortizacao do credito do dossier nº'||vCredito.credi_numcredito||' pagamento fazeado  '|| documentoUsar;

        valorFazeado := vPagamento.paga_prestacao + valorPagar; -- valorFazeado := valorFazeado1 + valorFazeado2;

        -- vPagamento.paga_prestacao <= valorPagar
        if vPagamento.paga_reembolso >= valorFazeado
          and vPagamento.paga_valoreal >= valorFazeado then

          -- RETURN ('(false, Calcular a difirenca a sobra)')::result;
          -- Calcular a diferencao do valor que ira sobrar
            -- Se a diferenca do valor for algumas sentezimas Entre 0 á 1 Entao adicionar essas centezimas ao valor a pagar
          diferencaValor := vPagamento.paga_reembolso - valorFazeado;
          if diferencaValor>0 and diferencaValor < 1 then
            valorPagar := valorPagar + diferencaValor;
          end if;

          if valorPagar + vPagamento.paga_prestacao  = vPagamento.paga_reembolso then
            dataDocumentoUsar := "dataDocumentoPagamento";
          end if;

          valido := true;
        else
          res.message := 'Valor inserido superio ao esperado. Pagamento fazeado não efectuado!'||'<br>Esperado : '||;
          return res;
        end if;
      end if;


      if valido then
        -- Amortizar a prestacao
        update pagamento
          set paga_partrance = porTranche,
            paga_prestacao = paga_prestacao + valorPagar,
            paga_numdocumentopagamentoreal = documentoUsar,
            paga_banco_idreal = bancoUsar,
            paga_dtendossado = dataDocumentoUsar
          where paga_id = "idPagamento";

        -- credial.funct_reg_bancomovimento("idUser", "idAgencia", "idBanco", debito, credito, libele character varying)

        -- Registrar as movimentocoes para o banco utilizado no pagamento
        resPay := funct_reg_bancomovimento(
          "idUser",
          "idAgencia",
          "idBancoReal",
          0,
          valorPagar,
          libele
        );
        
        res.message := resPay.message;
        
        -- Quando o pagamento for o pagamento fazeado tambem registar a movementacao do pagamento
        -- credial.funct_reg_pagamento_fazeado("idUser", "idAgencia", "idPagamento", "idBanco", "numeroDocumentoPagamento", "dataDocumentoPagamento", "valorPagamento")
        
        if "tipoPagamento" = 'F'
          and resPay.result = TRUE 
        then -- Siguin ifica faseado
          PERFORM  funct_reg_pagamento_fazeado(

              "idUser",
              "idAgencia",
              "idPagamento",
              bancoUsar,
              documentoUsar,
              "dataDocumentoPagamento",
              valorPagar

          );
        end if;

        -- contar quantos pagamentos abeto esse credito anida tem
        select count(*) into ttPagaOpen
          from pagamento pag
          where paga_state != 0
            and pag.paga_credi_id = vCredito.credi_id;

        -- Finalizar o credito caso nao tenha mais nehum pagamento aberto
        if ttPagaOpen = 0 then
          update credito
            set credi_state = 0,
              credi_creditostate = 0
            where credi_id = vCredito.credi_id;
        end if;
      end if;
      res.result := TRUE;
        return res;
    else 
      res.message:= 'Essa prestacao ja foi paga';
    END IF;
    
    return res;
  END;
$$
;