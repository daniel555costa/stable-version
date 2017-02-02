CREATE OR REPLACE FUNCTION funct_load_credito_client ("idUser" character varying, "idAgencia" numeric, "nifClient" character varying) RETURNS TABLE("ID" numeric, "DOSSIER" character varying, "CAPITAL INICIAL" character varying, "TOTAL CREDITO" character varying, "TAEG" character varying, "VALOR PAGO" character varying, "CHEQUE USADO" character varying, "DATA INICIO" character varying, "DATA FINALIZAR" character varying, "DATA FIM" character varying, "REGISTRO" character varying, "STATE" character varying, "STATE COD" numeric)
	LANGUAGE sql
AS $$
  select ce.credi_id as "ID",
      ce.credi_numcredito as "DOSSIER",-- numero de credito age como o umenro de dossier
      lib.money(ce.credi_totalpagar) as "CAPITAL INICIAL",
      lib.money(ce.credi_valuecredito) as "TOTAL CREDITO",
      lib.money(ce.credi_taeg) as "TAEG",
      lib.money(ce.credi_valuepago) as "VALOR PAGO",
      ce.credi_numcheque as "CHEQUE USADO",
      to_char(ce.credi_dtinicio, 'DD-MM-YYYY') as "DATA INICIO",
      to_char(ce.credi_dtfinalizar, 'DD-MM-YYYY') as "DATA FINALIZAR",
      to_char(ce.credi_dtfinalizar, 'DD-MM-YYYY') as "DATA FIM",
      to_char(ce.credi_dtrge, 'DD-MM-YYYY') as "REGISTRO",
      CASE
        when ce.credi_state = 1 then 'Por pagar'
        else 'Pago'
      END as "STATE",
    ce.credi_state as "STATE COD"
    from credito ce
    where ce.credi_dos_nif = "nifClient"
    ORDER BY ce.credi_dtrge DESC ;
$$
