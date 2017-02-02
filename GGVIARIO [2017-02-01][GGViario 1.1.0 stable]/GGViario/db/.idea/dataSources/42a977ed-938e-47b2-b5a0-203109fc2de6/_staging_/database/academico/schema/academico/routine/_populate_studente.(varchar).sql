CREATE or REPLACE FUNCTION _populate_studente (aux_curso character varying) RETURNS character varying
	LANGUAGE plpgsql
AS $$
   DECLARE
     anoAtual numeric = (to_char(now(), 'YYYY'))::NUMERIC;
   BEGIN
     insert into alunocandidato(
       alu_name,
       alu_surname,
       alu_state,
       alu_dtnasc,
       alu_sexo_id,
       alu_cod,
       aux_curo
     )  SELECT
          substr(name, 1, 32),
          name,
          2,
          to_date('01-01-'||(anoAtual-_loadstudent.idade), 'dd-mm-yyyy'),
          case
            when sexo = 'M' then 1
             else 2
          end,
          cod,
          aux_curso

     

     from _loadstudent;
     DELETE from _loadstudent;
     RETURN '';
   END;
$$
