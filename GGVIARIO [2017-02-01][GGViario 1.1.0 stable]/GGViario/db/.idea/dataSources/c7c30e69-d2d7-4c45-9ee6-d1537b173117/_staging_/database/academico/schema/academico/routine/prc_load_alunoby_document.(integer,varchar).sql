CREATE FUNCTION prc_load_alunoby_document (idtipodoc integer, numerodoc character varying)
  RETURNS TABLE(
    "ALUNO.ID" numeric,
    "ALUNO.NAME" character varying,
    "ALUNO.APELIDO" character varying,
    "ALUNO.DATANASCIMENTO" character varying,
    "ALUNO.SEXOID" numeric,
    "DISTRITO.ID" numeric,
    "MORADA.ID" numeric,
    "ALUNO.TELEFONE" character varying,
    "ALUNO.EMAIL" character varying
  )
	LANGUAGE plpgsql
AS $$
  declare 
     idAluno integer DEFAULT funct_checkDoc(idTipoDoc, numeroDoc);
  begin
  
    if idAluno != 0 then
        RETURN QUERY SELECT alu.alu_id as "ALUNO.ID",
              alu.alu_name as "ALUNO.NOME",
              alu.alu_surname as "ALUNO.APELIDO",
              DATE_FORMAT(alu.alu_dtnasc, '%d-%m-%Y') as "ALUNO.DATANASCIMENTO",
              s.sexo_id as "ALUNO.SEXOID",
              dist.dist_id as "DISTRITO.ID",
              local.local_id as "MORADA.ID",
             (SELECT co.cont_contacto
              from contacto co
                  INNER JOIN typecontacto typeC on typeC.tpcont_id = co.cont_tpcont_id
              WHERE co.cont_tpcont_id = 1
                  AND co.cont_alu_id = alu.alu_id
                  and co.cont_state =1
                  and typeC.tpcont_state =1) as "ALUNO.TELEFONE",
          (SELECT co.cont_contacto
              from contacto co
                  INNER JOIN typecontacto typeC on typeC.tpcont_id = co.cont_tpcont_id
              WHERE co.cont_tpcont_id = 2
                  AND co.cont_alu_id = alu.alu_id
                  and co.cont_state =1
                  and typeC.tpcont_state =1) as "ALUNO.EMAIL"
            from aluno_candidato alu
              INNER JOIN sexo s on s.sexo_id= alu.alu_sexo_id
              INNER JOIN residencia res on  res.res_alu_id = alu.alu_id
              INNER JOIN localidade local on local.local_id = res.res_local_id
              INNER JOIN distrito dist on dist.dist_id = local.local_dist_id
         WHERE res.res_state =1
          and  local.local_state =1
          and dist.dist_estado = 1
          and alu.alu_id =idAluno;

    END IF;
   END;
$$
