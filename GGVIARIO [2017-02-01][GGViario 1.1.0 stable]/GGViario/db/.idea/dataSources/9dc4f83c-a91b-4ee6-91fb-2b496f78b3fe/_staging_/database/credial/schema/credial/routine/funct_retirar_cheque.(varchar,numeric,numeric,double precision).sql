CREATE OR REPLACE FUNCTION funct_retirar_cheque ("idUser" character varying, "idAgencia" numeric, idconta numeric, "valorRequisicao" double precision) RETURNS TABLE("RESULT" boolean, "ID CHEQUE" numeric, "NUM SEQUENCIA" character varying, "MESSAGE" character varying)
	LANGUAGE plpgsql
AS $$
  DECLARE
    cheque chequempresa;
  BEGIN
    "RESULT" := false;
    cheque := rule.get_cheque_randon("idUser", idconta, "idAgencia", "valorRequisicao");

    if cheque.cheq_id is not null then
      "RESULT" := true;
      "ID CHEQUE" := cheque.cheq_id;
      "NUM SEQUENCIA" := substr(cheque.cheq_sequencefim, 0, length(cheque.cheq_sequencefim) -3);
      "MESSAGE" := 'success';
    else
      "MESSAGE" := message('NO.CHEQUE.AVALIBLE');
    END IF;
    return next;
  END;
$$
