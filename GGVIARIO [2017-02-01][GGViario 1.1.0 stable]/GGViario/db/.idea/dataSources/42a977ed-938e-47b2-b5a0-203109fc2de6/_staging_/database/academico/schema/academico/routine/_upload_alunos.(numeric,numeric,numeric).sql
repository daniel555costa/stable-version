DROP FUNCTION _upload_alunos (idcurso numeric, anoatual numeric, periodo numeric) ;-- RETURNS TABLE(result boolean, message character varying, code character varying, name character varying, sexo character varying, idade character varying)
CREATE or REPLACE FUNCTION _upload_alunos ( fileName CHARACTER VARYING, idcurso numeric, anoatual numeric, periodo numeric) RETURNS TABLE(result boolean, message character varying, code character varying, name character varying, sexo character varying, idade character varying)
	LANGUAGE plpgsql
AS $$

  DECLARE
    vAnoLecivo anolectivo;
    vVagas RECORD;
    vCurso curso;
    currentYear numeric = (to_char(now(), 'YYYY'))::NUMERIC;
    i _loadstudent;
    vExist numeric;

    vAlunoStudent alunocandidato;
    idSexo NUMERIC;
    tipoProblema NUMERIC;

  BEGIN
    DELETE from _loadstudent;
    COPY _loadstudent FROM  '/srv/http/Lista_owrk/simple.csv' CSV DELIMITER ';';

    SELECT * into vAnoLecivo
      from anolectivo
      where ano_inicial = 2016 - anoAtual;

    SELECT * 
       into vCurso
       from curso
       WHERE  cur_id = idcurso;

    RAISE NOTICE 'anoAtual: %, %', anoAtual, vAnoLecivo;
    SELECT * into vVagas
       from funct_reg_vaga(
          idcurso,
          50,
          vAnoLecivo.ano_id,
          (SELECT to_date((SELECT ano_inicial||''
                           from anolectivo where ano_inicial = 2016 - anoAtual), 'yyyy')),
          (SELECT to_date((SELECT ano_inicial||''
                           from anolectivo where ano_inicial = 2016 - anoAtual), 'yyyy')),
          periodo
        ) vaga(result, message, id, codcurso);

    for i in (
      SELECT *
        from _loadstudent
    ) LOOP
      select count(*)  into vExist
        from alunocandidato a
        where a.alu_cod = i.cod;

      if i.sexo = 'M' THEN  idSexo := 1; else idSexo := 2; END IF;

      if vExist = 0 then
        insert into alunocandidato(
           alu_name,
           alu_surname,
           alu_state,
           alu_dtnasc,
           alu_sexo_id,
           alu_cod,
           aux_curo
         )  VALUES(
              substr(i.name, 1, 32),
              i.name,
              2,
              to_date((currentYear - i.idade)::CHARACTER VARYING, 'yyyy'),
              idSexo,
              i.cod,
              vVagas.codcurso
        );

        PERFORM _populate_inscricao(vVagas.id::INTEGER);

        result := true;
        message := 'sucesso';
        code := i.cod;
        name := i.name;
        sexo := i.sexo;
        idade := i.idade;
        RETURN next;
      else

        select * into vAlunoStudent
          from alunocandidato
          where alu_cod = i.cod;

        if vAlunoStudent.alu_cod = i.cod
          and upper(vAlunoStudent.alu_surname) = upper(i.name)
          and vAlunoStudent.alu_sexo_id = idSexo
        THEN

          result := false;
          message := 'aluno ja cadastrado skip';
          code := i.cod;
          name := i.name;
          idade := i.idade;
          tipoProblema := 2;
          RETURN NEXT;

        else

          result := false;
          message := 'Integridade violada (alunos diferentes com memo nome)';
          code := i.cod;
          name := i.name;
          idade := i.idade;
          tipoProblema := 1;
          RETURN NEXT;

        END IF;

        INSERT INTO _alunosproblematicos (
          cod,
          name,
          sexo,
          idade,
          curso,
          vaga,
          ano,
          periodo,
          typeproblema,
          other
        ) VALUES (
          i.cod,
          i.name,
          i.sexo,
          i.idade,
          vCurso.cur_name,
          vVagas.id,
          anoAtual,
          periodo,
          tipoProblema,
          vAlunoStudent
        );
        
      END IF;
    END LOOP;

     DELETE from _loadstudent;
  END;
$$
