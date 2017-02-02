CREATE or REPLACE FUNCTION rule.get_taxa_periodo_superior ("quantidadePeriodoRequitado" numeric, "idTipoCredito" numeric) RETURNS credial.taxa
	LANGUAGE sql
AS $$

  select *
    from credial.taxa tx
    where tx.taxa_obj_tipocredito = "idTipoCredito"
      and tx.taxa_state = 1
      and tx.taxa_periodo > "quantidadePeriodoRequitado"
    order by tx.taxa_periodo asc
    limit 1;
$$
