CREATE  OR REPLACE FUNCTION funct_datasource_client_simple () RETURNS TABLE("NIF" character varying, "NAME" character varying, "SURNAME" character varying, "DOSSIER" character varying, "TELE" character varying, "ID AGENCIA" integer, "QUANTIDADE DE CREDITO" integer, name_noaccent character varying, surname_noaccent character varying)
	LANGUAGE sql
AS $$
    SELECT DISTINCT dos.dos_nif AS "NIF",
        dos.dos_name AS "NAME",
        dos.dos_surname AS "SURNAME",
        dos.dos_numdos AS "DOSSIER",
            CASE
                WHEN (hi.hisdos_telmovel IS NOT NULL) THEN hi.hisdos_telmovel
                WHEN (hi.hisdos_telservico IS NOT NULL) THEN hi.hisdos_telservico
                WHEN (hi.hisdos_telfixo IS NOT NULL) THEN hi.hisdos_telfixo
                ELSE 'NA'::character varying
            END AS "TELE",
        (dos.dos_age_id)::integer AS "ID AGENCIA",
        (count(ce.credi_id))::integer AS "QUANTIDADE DE CREDITO",
        upper(btrim(lib.funaccent((dos.dos_name)::text))) AS "S_NAME",
        upper(btrim(lib.funaccent((dos.dos_surname)::text))) AS "S_SURNAME"
       FROM credial.dossiercliente dos
         LEFT JOIN credial.credito ce ON dos.dos_nif = ce.credi_dos_nif
         LEFT JOIN credial.funct_historicocliente(dos.dos_nif) hi ON dos.dos_nif = hi.hisdos_dos_nif
      GROUP BY dos.dos_nif, dos.dos_name, dos.dos_surname, dos.dos_numdos,
            CASE
                WHEN (hi.hisdos_telmovel IS NOT NULL) THEN hi.hisdos_telmovel
                WHEN (hi.hisdos_telservico IS NOT NULL) THEN hi.hisdos_telservico
                WHEN (hi.hisdos_telfixo IS NOT NULL) THEN hi.hisdos_telfixo
                ELSE 'NA'::character varying
            END, dos.dos_age_id
      ORDER BY dos.dos_name, dos.dos_surname, dos.dos_nif
$$
