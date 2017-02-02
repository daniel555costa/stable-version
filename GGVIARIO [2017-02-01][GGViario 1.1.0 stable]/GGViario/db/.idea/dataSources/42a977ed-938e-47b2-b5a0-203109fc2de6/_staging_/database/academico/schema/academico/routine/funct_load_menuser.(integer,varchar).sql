CREATE or REPLACE FUNCTION funct_load_menuser (iduser integer, typedomain character varying) RETURNS TABLE(
  "ID" numeric,
  "NAME" character varying,
  "CODE" character varying,
  "LINK" character varying,
  "SUPER.ID" numeric,
  "SUPER.NAME" character varying,
  "SUPER.CODE" character varying,
  "SUPER.LINK" character varying,
  "MENU.HASCHILDREN" boolean,
  "MENU.LEVEL" character varying,
  "MENU.RAIZ" character varying,
  "MENU.USE-LINK" boolean
)
	LANGUAGE plpgsql
AS $$
  BEGIN
      if upper(typeDomain) in ('STUD', 'DOSC') THEN
        return query SELECT m.mn_id as "ID",
               m.mn_name as "NAME",
               SUBSTR(concat(md5((random()*999999)::CHARACTER VARYING)), 1, 10)::CHARACTER VARYING as "CODE",
               m.mn_link as "LINK",
               m.mn_mn_id as "SUPER.ID",
               m.mn_mn_name as "SUPER.NAME",
               m.mn_mn_code as "SUPER.CODE",
               m.mn_mn_link as "SUPER.LINK",
               m.mn_haschidren::BOOLEAN as "MENU.HASCHILDREN",
               m.mn_level as "MENU.LEVEL",
               m.mn_raiz as "MENU.RAIZ",
               m.mn_uselink as "MENU.USE-LINK"
            from ver_menu_structure m
            WHERE upper(m.udom_usertype) = upper(typeDomain);
      ELSE
        return query SELECT m.mn_id as "ID",
             m.mn_name as "NAME",
             SUBSTR(concat(md5((random()*999999)::CHARACTER VARYING)), 1, 10)::CHARACTER VARYING as "CODE",
             m.mn_link as "LINK",
             m.mn_mn_id as "SUPER.ID",
             m.mn_mn_name as "SUPER.NAME",
             m.mn_mn_code as "SUPER.CODE",
             m.mn_mn_link as "SUPER.LINK",
             m.mn_haschidren::BOOLEAN as "MENU.HASCHILDREN",
             m.mn_level as "MENU.LEVEL",
             m.mn_raiz as "MENU.RAIZ",
             m.mn_uselink::BOOLEAN as "MENU.USE-LINK"
          from ver_menu_structure m
            inner JOIN menuser muser on m.mn_id = muser.muser_mn_id
          where muser.muser_user_user = idUser;
      END IF;
  END
  
$$
