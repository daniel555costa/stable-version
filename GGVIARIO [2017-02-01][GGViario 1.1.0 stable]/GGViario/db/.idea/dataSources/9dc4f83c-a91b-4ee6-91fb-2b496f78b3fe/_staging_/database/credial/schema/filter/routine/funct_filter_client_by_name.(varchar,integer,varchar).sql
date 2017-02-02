CREATE OR REPLACE FUNCTION funct_filter_client_by_name ("idUser" character varying, "idAgencia" integer, "clientName" character varying) RETURNS TABLE("NIF" character varying, "NAME" character varying, "SURNAME" character varying, "DOSSIER" character varying, "TELE" character varying, "ID AGENCIA" integer, "QUANTIDADE DE CREDITO" integer)
	LANGUAGE plpgsql
AS $$
  DECLARE
    noAccentName TEXT DEFAULT upper(lib.funaccent("clientName"));
  BEGIN
    RETURN QUERY
      SELECT mcs."NIF",
              mcs."NAME",
              mcs."SURNAME",
              mcs."DOSSIER",
              mcs."TELE",
              mcs."ID AGENCIA",
              mcs."QUANTIDADE DE CREDITO"
        from filter.mver_client_simple mcs
        where  mcs.name_noaccent LIKE  '%'||noAccentName||'%'
               OR mcs.surname_noaccent LIKE  '%'||noAccentName||'%'
               ;
  END;
$$
