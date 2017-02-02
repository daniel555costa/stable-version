CREATE OR REPLACE FUNCTION funct_confirm_regcredito ("idUser" character varying, "idAgencia" numeric, "idCredito" numeric, "idBanco" numeric, "totalDocumentoEntreges" numeric, "totalGarantiaCredito" numeric) RETURNS TABLE("RESULT" boolean, "MESSAGE" character varying, "NUM DOSSIER" character varying, "NUM CHEQUE" character varying, "BANCO NAME" character varying, "BANCO SIGLA" character varying)
	LANGUAGE plpgsql
AS $$
  DECLARE
    vCredito credito;
    ttDocumento numeric;
    ttGarantia numeric;
    ttPagamento numeric;
    vBanco banco;

    message character varying;
    messageGarrantia character varying;
    messagePagamento character varying;
    messageDocumneto character varying;
    libele character varying;
    res "Result";
  BEGIN

    "RESULT" := false;
    -- Carregar todas as informacoes do credito
    select * into vCredito
      from credito ce
      where ce.credi_id = "idCredito";

    -- Buscar a quantidade de registros de pagamento, documentos e garrantias registradas
    -- Buscar a aquantidade de documento entrege
    select count(*) into ttDocumento
      from documentoentregue de
      where de.docentre_credi_id = "idCredito";

    -- Buscar a quantidade de pagamento registrado
    select count(*) into ttPagamento
      from pagamento pa
      where pa.paga_credi_id = "idCredito";

    -- Buscar pela quantidade de garrantia registrada nesse credito
    select count(*)  into ttGarantia
      from garrantiacredito ga
      where ga.garcredi_credi_id = "idCredito";

    -- Buscar pelo banco para poder criar a messagem
    select * into vBanco
      from banco bc
        INNER JOIN conta ct on bc.banco_id = ct.conta_banco_id
        inner join chequempresa ch on ch.cheq_conta_id = ct.conta_id
      where cheq_id = vCredito.credi_cheq_id;

    -- "O numero do dossier é:"+ getId.split(";")[1]+ " e Cheque a atribuir Numero: "+getSequenciaCheque()+" do Banco: "+bancoCredito.split(";")[1]) );

    -- Se a quantidade de pagamento refistrado for igua a total de pagamento fornecido
      -- E a quantidade dos documentos e garrantia encontraa for miaor que zera e menor ou igual a quantidade fornecida
      -- Nesse caso deve ser criado a menssagem de sucesso e finalizar o credito

    if ttPagamento = vCredito.credi_numprestacao
      and ttDocumento >= 1 and ttDocumento <= "totalDocumentoEntreges"
      and ttGarantia >= 1 and  ttGarantia <= "totalGarantiaCredito"
    then
      -- Criar a movimentacao no banco
      libele := 'Pagamento do cheque nº'||vCredito.credi_numcheque||' para o credito nº'||vCredito.credi_numcredito;
      res := funct_reg_bancomovimento("idUser", "idAgencia", "idBanco", vCredito.credi_valuecredito, 0.0, libele);
      "MESSAGE" := message('CREDITO.REG.SUCCESS');
      "NUM DOSSIER" := vCredito.credi_numcredito;
      "NUM CHEQUE" := vCredito.credi_numcheque;
      "BANCO NAME" := vBanco.banco_name;
      "BANCO SIGLA" := vBanco.banco_sigla;
      "RESULT" := true;

      messageGarrantia := (case when ttGarantia != "totalGarantiaCredito" then message('REG.GARRANTIA.INCONPLET')  else null end);
      messageDocumneto :=  (case when ttDocumento != "totalDocumentoEntreges" then message('REG.DOCUMENT.INCOMPLETE') else null end);
      "MESSAGE" := "MESSAGE"
          || (case when messageDocumneto is not null then ln()||messageDocumneto else  '' end)
          || (case when messageGarrantia is not null then ln()|| messageGarrantia else '' end);
      
    ELSE
      -- Para o caso contrario deve ser difeitos totas as alteracoes aplicadas
      messageGarrantia := (case
                            when ttGarantia = 0 then message('CREDITO.GARANTIA.NOT-REG')
                            when ttGarantia != "totalGarantiaCredito" then message('REG.GARRANTIA.INCONPLET')
                            else ''
                          end);

      messageDocumneto := (CASE
                            when ttDocumento = 0  then message('CREDITO.DOCUMENTO.NOT-REG')
                            when ttDocumento != "totalDocumentoEntreges" then message('REG.DOCUMENT.INCOMPLETE')
                            else ''
                          end);

      messagePagamento := (case when ttPagamento != vCredito.credi_numprestacao then message('CREDITP.PAY.NOT-REG') else '' end);

      "MESSAGE" := message('CREDITO.NOT-REG')
          || (case when messagePagamento is not null then ln()||messagePagamento else '' end)
          || (case when messageDocumneto is not null then ln()||messageDocumneto else '' end)
          || (case when messageGarrantia is not null then ln()||messageGarrantia else '' end)
          || ln()
          || ln()||'totalDocumentoEntreges : '||"totalDocumentoEntreges"
          || ln()||'ttDocumento : '||ttDocumento
          || ln()||'totalGarantiaCredito : '||"totalGarantiaCredito"
          || ln()||'ttGarantia : '||ttGarantia
      ;

      /*
      -- Repor o saldo virtual do banco
      update banco
        set0.... banco_saldovirtual = banco_saldovirtual + vCredito.credi_valuecredito
        where banco_id ="idBanco";
      
      -- Remover todas as garrantias que puderao ser registradas
      delete from garrantiacredito
        where garcredi_credi_id = "idCredito";
      
      -- Remover todos os pagamentos registrados para esse credito
      delete from pagamento
        where paga_credi_id = "idCredito";
      
      -- Remover todos os documentos
      delete from documentoentregue 
        where docentre_credi_id = "idCredito";
      
      -- Remover o proprio credito
      delete from credito 
        where credi_id = "idCredito";
      */
    END IF;
    
    return next;
  END;
$$
