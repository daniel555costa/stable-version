CREATE or REPLACE FUNCTION rule.funct_update_penalidade (valorpenalidade double precision, idcredito integer, nifcliente character varying) RETURNS credial.result
	LANGUAGE sql
AS $$

    update credial.credito
      set credi_penalidade  = valorPenalidade,
          credi_dtpenalidade = now()
      where credi_dos_nif = nifCliente
        and credi_id = idCredito
        and credito.credi_state = 1;

    SELECT '(true,sucesso)'::credial.result;
$$
