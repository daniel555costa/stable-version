CREATE or REPLACE FUNCTION funct_filter_client_by_garrantia ("idUser" character varying, "idAgencia" integer, argment character varying) RETURNS TABLE("NIF" character varying, "NAME" character varying, "SURNAME" character varying, "DOSSIER" character varying, "TELE" character varying, "ID AGENCIA" integer, "QUANTIDADE DE CREDITO" integer)
	LANGUAGE plpgsql
AS $$
  DECLARE
    noAccentArgment TEXT DEFAULT '%'||UPPER(lib.funaccent("argment"))||'%';
  BEGIN
    RETURN QUERY
      SELECT DISTINCT mcs."NIF",
              mcs."NAME",
              mcs."SURNAME",
              mcs."DOSSIER",
              mcs."TELE",
              mcs."ID AGENCIA",
              mcs."QUANTIDADE DE CREDITO"
        from filter.mver_client_garantias mcs
        where mcs.garrantia_noaccent LIKE noAccentArgment
          or mcs.typegarrantia_noaccent LIKE noAccentArgment;
  END;
$$
