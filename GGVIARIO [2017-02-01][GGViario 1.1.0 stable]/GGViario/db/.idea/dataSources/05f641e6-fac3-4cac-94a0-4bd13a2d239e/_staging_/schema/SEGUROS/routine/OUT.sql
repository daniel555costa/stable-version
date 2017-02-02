create or REPLACE PROCEDURE           "OUT" (argment CLOB)
IS
BEGIN
  INSERT into output VALUES (argment);
END;