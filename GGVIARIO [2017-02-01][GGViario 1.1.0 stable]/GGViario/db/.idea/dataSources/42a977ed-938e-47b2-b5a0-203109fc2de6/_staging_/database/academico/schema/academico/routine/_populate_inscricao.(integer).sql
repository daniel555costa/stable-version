CREATE or REPLACE FUNCTION _populate_inscricao (idvaga integer) RETURNS character varying
	LANGUAGE plpgsql
AS $$

declare
   codcurso CHARACTER VARYING;
BEGIN

  SELECT c.cur_codigo into codcurso
    from vaga v
      INNER JOIN curso c on v.vaga_cur_id = c.cur_id
  where v.vaga_id = idVaga;

  INSERT into inscricao (
    insc_alu_id,
    insc_vaga_id,
    insc_result,
    insc_mediacertificad,
    insc_option,
    insc_state
  ) SELECT
      a.alu_id,
      idVaga,
      1,
      20,
      1,
      1
    from alunocandidato a
    where alu_state = 2
      and aux_curo = codcurso;
  
  

  UPDATE alunocandidato set alu_state = 1 where alu_state = 2 and aux_curo = codcurso;
  UPDATE vaga set vaga_state = 0 where vaga_id = idVaga;
  
  RETURN 'feito';

END;

$$
