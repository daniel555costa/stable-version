CREATE or REPLACE FUNCTION funct_load_aluno (filter json) RETURNS TABLE("ID" numeric, "CODE" character varying, "NAME" character varying, "SURNAME" character varying, "CURSO" character varying, "ANO_ATUAL" character varying, "SEXO" character varying, "IDADE" numeric, "MORADA" character varying, "CONTACTO" character varying, "SEXO_COD" character, "SEXO_ID" numeric)
	LANGUAGE plpgsql
AS $$
  DECLARE
    i RECORD;
    vAnoLectivo anolectivo;
    current_year numeric DEFAULT to_char(now(), 'yyyy')::NUMERIC;
    difAno NUMERIC DEFAULT  0;
  BEGIN
    SELECT * into vAnoLectivo from anolectivo ORDER BY ano_inicial desc LIMIT  1;
    if current_year = vAnoLectivo.ano_final then
      difAno := 1;
    end if;
    for i in (
      SELECT *
        from alunocandidato a
          INNER JOIN inscricao ins ON a.alu_id = ins.insc_alu_id
          INNER JOIN vaga v on ins.insc_vaga_id = v.vaga_id
          INNER JOIN anolectivo anovaga on v.vaga_ano_id = anovaga.ano_id
          INNER JOIN curso c on v.vaga_cur_id = c.cur_id
          INNER JOIN sexo s on a.alu_sexo_id = s.sexo_id
    ) LOOP
      "ID" := i.alu_id;
      "CODE" := i.alu_cod;
      "NAME" := i.alu_name;
      "SURNAME" := i.alu_surname;
      "CURSO" := i.cur_name;


      "ANO_ATUAL" := to_char(now(), 'yyyy')::numeric - i.ano_inicial - difAno;

      "SEXO" :=i.sexo_desc;
      "IDADE" := lib.age(i.alu_dtnasc);
      "MORADA" := 'Morada';
      "CONTACTO" := 'contacto';
      "SEXO_COD" := case when i.sexo_id = 1 then 'M' else 'F' END;
      "SEXO_ID" := i.sexo_id;
      RETURN  NEXT;
    END LOOP;
  END;
$$
