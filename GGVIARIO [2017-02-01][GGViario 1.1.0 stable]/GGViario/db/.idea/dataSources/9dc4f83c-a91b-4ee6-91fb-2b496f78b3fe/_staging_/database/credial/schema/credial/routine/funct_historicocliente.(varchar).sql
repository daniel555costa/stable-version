DROP FUNCTION funct_historicocliente ("nifCliente" character varying);
CREATE FUNCTION funct_historicocliente ("nifCliente" character varying) RETURNS SETOF historicocliente
	LANGUAGE sql
AS $$
  SELECT *
    from historicocliente h 
    where h.hisdos_dos_nif = "nifCliente"
      and h.hisdos_state = 1
    ORDER BY  h.hisdos_dtreg desc
    limit 1
$$
