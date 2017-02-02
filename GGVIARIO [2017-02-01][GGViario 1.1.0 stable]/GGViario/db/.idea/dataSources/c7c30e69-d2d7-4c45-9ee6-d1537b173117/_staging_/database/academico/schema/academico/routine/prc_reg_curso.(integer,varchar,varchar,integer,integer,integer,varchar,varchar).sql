CREATE FUNCTION prc_reg_curso (id_departamento integer, curso_name character varying, saidas_proficionais character varying, id_grau_academico integer, codigo_curso integer, duracao integer, objectivo character varying, curso_continuidade character varying) RETURNS academico.result
	LANGUAGE plpgsql
AS $$
  BEGIN
  IF (CURSO_NAME=(SELECT cur_name FROM curso C WHERE UPPER(cur_name)=UPPER(CURSO_NAME))) THEN
     select false as RESULT, 'Já existe curso com este nome.' as MESSAGE;
  ELSE
    INSERT INTO curso(cur_dep_id,
                      cur_name,
                      cur_saidasproficionais,
                      grau_academico_id,
                      cur_cursocontinuidade,
                      cur_objetivo,
                      cur_codigo,
                      cur_duracao)VALUES(ID_DEPARTAMENTO,
                                               CURSO_NAME,
                                               SAIDAS_PROFICIONAIS,
                                               ID_GRAU_ACADEMICO,
                                               CURSO_CONTINUIDADE,
                                               OBJECTIVO,
                                               CODIGO_CURSO,
                                               DURACAO);
    return '(true,null)'::result;
  END IF;
END
$$
