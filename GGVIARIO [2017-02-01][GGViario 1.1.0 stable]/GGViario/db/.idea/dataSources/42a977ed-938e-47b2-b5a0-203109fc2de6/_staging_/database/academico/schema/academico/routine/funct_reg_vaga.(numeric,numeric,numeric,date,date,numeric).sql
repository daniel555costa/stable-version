CREATE or REPLACE FUNCTION funct_reg_vaga (idcurso numeric, numvagas numeric, idanolectivo numeric, datainicio date, datafim date, idperiodo numeric)
  RETURNS TABLE(
    result BOOLEAN,
    message CHARACTER VARYING,
    id NUMERIC,
    codcurso CHARACTER VARYING
  )
	LANGUAGE plpgsql
AS $$
  DECLARE
    idVaga NUMERIC;
  BEGIN 
    INSERT into vaga(
      vaga_cur_id, 
      vaga_numero, 
      vaga_ano_id,
      vaga_datainicio, 
      vaga_datafim,
      vaga_periodo_id
    ) VALUES (
      idCurso,
      numVagas,
      idAnoLectivo,
      dataInicio,
      dataFim,
      idPeriodo
    ) RETURNING vaga_id into idVaga;

    result := true;
    message := 'success';
    id := idVaga;
    codcurso := (SELECT c.cur_codigo from curso c where c.cur_id = idcurso);

    RETURN NEXT;
  END;
$$
