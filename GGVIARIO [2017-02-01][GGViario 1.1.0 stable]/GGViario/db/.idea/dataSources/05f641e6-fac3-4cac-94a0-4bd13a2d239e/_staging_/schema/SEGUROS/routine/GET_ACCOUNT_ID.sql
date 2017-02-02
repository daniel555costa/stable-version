create  or REPLACE function get_account_id (
   number_account CHARACTER VARYING
) return number 
is
   recuver number;
BEGIN
   SELECT ID into recuver
      from VER_ACCOUNT
      WHERE "NUMBER" = number_account;


   RETURN  recuver;

   EXCEPTION
     WHEN NO_DATA_FOUND  THEN
     RETURN  NULL;
     WHEN OTHERS  THEN RETURN  NULL;
END;