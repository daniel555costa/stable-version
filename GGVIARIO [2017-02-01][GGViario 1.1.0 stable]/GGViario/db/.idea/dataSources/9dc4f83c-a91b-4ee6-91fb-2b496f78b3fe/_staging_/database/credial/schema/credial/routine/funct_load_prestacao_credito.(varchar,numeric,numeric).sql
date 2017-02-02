CREATE OR REPLACE FUNCTION funct_load_prestacao_credito ("idUser" character varying, "idAgencia" numeric, "idCredito" numeric) RETURNS TABLE("ID" numeric, "DATA EMISAO" character varying, "DATA ENDOSSADO" character varying, "REEMBOLSO" character varying, "PRESTACAO PAGA" character varying, "DOCUMENTO PAGAMENTO" character varying, "STATE" character varying, "STATE COD" numeric, "TRANCHE" character varying, "TRANCHE COD" numeric, "DATA FECHO PRESTACAO" character varying, "BANCO PREVISTO ID" integer, "BANCO REAL ID" integer)
	LANGUAGE sql
AS $$
  select
        pa.paga_id as "ID",
        to_char(pa.paga_dtsaque, 'DD-MM-YYYY') as "DATA SAQUE COMO A DATA ENDOSSADO",
        to_char(pa.paga_dtendossado, 'DD-MM-YYYY') as "DATA ENDOSSADO",
        lib.money(pa.paga_reembolso) as "REEBOLSO",
        lib.money(pa.paga_prestacao) as "PRESTACAO JA PAGA",
        pa.paga_numdocumentopagamento as "NUMERO DE DOCUMENTO DE PAGAMENTO (DOCUMENTO FORNECIDO PELO BANCO)",
        case
          when pa.paga_state = 1 and pa.paga_partrance = 0 then 'Por pagar'
          when pa.paga_state = 1 and pa.paga_partrance = 1 then 'Por pagar (por pranche)'
          when pa.paga_state = 0 and pa.paga_partrance = 1 then 'Pago (por tranche)'
          when pa.paga_state = 0 and pa.paga_partrance = 0 then 'Pago'
          else 'Pago'
        end as "STATE",
      pa.paga_state as "STATE COD",
      case
        when pa.paga_partrance = 1 then 'Sim'
        else 'Não'
      end as "TRANCE",
      pa.paga_partrance as "POR TRANCE COD",
      to_char(pa.paga_dtdocumentopagamentoreal, 'DD-MM-YYYY') as "DATA DE FECHO DE PRESTACAO COMO A DATA FIM PAGAMENTO COMO A DATA DOCUMENTO PAGAMNETO REAL",
      pa.paga_banco_id::integer,
      pa.paga_banco_idreal::integer
    from pagamento pa
    where pa.paga_credi_id = "idCredito"
    ORDER BY pa.paga_dtreg DESC;
$$
