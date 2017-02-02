CREATE FUNCTION filter.funct_filter_client ("idUser" character varying, "idAgencia" integer, argment character varying) RETURNS TABLE("NIF" character varying, "NAME" character varying, "SURNAME" character varying, "DOSSIER" character varying, "TELE" character varying, "ID AGENCIA" integer, "QUANTIDADE DE CREDITO" integer)
	LANGUAGE sql
AS $$
    SELECT *
      from (
        SELECT *
              from filter.funct_filter_client_by_credito_garantias("idUser", "idAgencia", argment) c
                  UNION SELECT *
                     from filter.funct_filter_client_by_document_payment("idUser", "idAgencia", argment) c1
                  UNION SELECT *
                          from filter.funct_filter_client_by_name("idUser", "idAgencia", argment) c1
                  UNION SELECT *
                          from filter.funct_filter_client_by_nif("idUser", "idAgencia", argment) c1
    ) clients
     ORDER BY clients."NAME" ASC, clients."SURNAME" ASC
$$
