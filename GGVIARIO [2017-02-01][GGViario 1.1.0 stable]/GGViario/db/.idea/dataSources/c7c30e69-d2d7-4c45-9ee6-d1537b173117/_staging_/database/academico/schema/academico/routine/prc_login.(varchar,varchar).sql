CREATE FUNCTION funct_login (accessname character varying, pwd character varying) RETURNS TABLE("ID" numeric, "DOMAIN.ID" numeric, "USER.NAME" character varying, "USER.SURNAME" character varying, "DOMAIN.TYPE" character varying, "DOMAIN.DOMANIN" character varying, "USER.ACCESSNAME" character varying, "USER.ACCESS" numeric, "USER.DTREG" timestamp without time zone, "USER.ACCESS-DESC" character varying)
	LANGUAGE sql
AS $$
    SELECT
          users."ID",
          users."DOMAIN.ID",
          users."USER.NAME",
          users."USER.SURNAME",
          users."DOMAIN.TYPE",
          users."DOMAIN.DOMAIN",
          users."USER.ACCESSNAME",
          users."USER.ACCESS",
          users."USER.DTREG",
          CASE
            WHEN users."USER.ACCESS" = 1 THEN 'Ativo'
            WHEN users."USER.ACCESS" = 2 then 'Pré-ativo'
            ELSE NULL 
          END AS "USER.ACCESS-DESC"
      
        FROM ver_all_user users
        WHERE upper(users."USER.ACCESSNAME") = upper(accessName) 
              AND  users."USER.PWD" = md5(pwd)
              AND users."USER.ACCESS" !=0;
  
$$
