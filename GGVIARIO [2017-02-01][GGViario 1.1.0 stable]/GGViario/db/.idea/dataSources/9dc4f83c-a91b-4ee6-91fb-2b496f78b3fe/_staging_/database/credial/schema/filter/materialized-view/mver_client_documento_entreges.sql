CREATE MATERIALIZED VIEW mver_client_documento_entreges AS
SELECT mcs."NIF",
    mcs."NAME",
    mcs."SURNAME",
    mcs."DOSSIER",
    mcs."TELE",
    mcs."ID AGENCIA",
    mcs."QUANTIDADE DE CREDITO",
    mcs."S_NAME",
    mcs."S_SURNAME",
    upper(lib.funaccent((docs.docentre_desc)::text)) AS num_document_entregue,
    upper(lib.funaccent((tpdoc.obj_desc)::text)) AS type_document,
    docs.docentre_desc AS "NUM DOCUMENT ENTREGE",
    tpdoc.obj_desc AS "TYPE DOCUMENT"
   FROM (((filter.mver_client_simple mcs
     JOIN credito ce ON (((mcs."NIF")::text = (ce.credi_dos_nif)::text)))
     JOIN documentoentregue docs ON ((ce.credi_id = docs.docentre_credi_id)))
     JOIN objecto tpdoc ON ((docs.docentre_obj_tipodocumento = tpdoc.obj_id)));