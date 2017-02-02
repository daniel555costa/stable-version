CREATE OR REPLACE FUNCTION rule.get_taxa_periodo_inferior ("quantidadePeriodo" numeric, "idTypeCredito" numeric) RETURNS credial.taxa
	LANGUAGE sql
AS $$

  select *
    from credial.taxa tx
    where tx.taxa_obj_tipocredito = "idTypeCredito"
      and tx.taxa_state = 1
      and tx.taxa_periodo <= "quantidadePeriodo"
    order by tx.taxa_periodo desc
    limit 1;
$$
