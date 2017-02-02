CREATE FUNCTION rule.get_seguro_activo () RETURNS seguro
	LANGUAGE sql
AS $$
  
  select *
    from credial.seguro se 
    where se.seg_state = 1
    order by se.seg_dtreg desc,
      se.seg_id desc
    limit 1;
$$
