CREATE FUNCTION `age`(`ano` DATE)
  RETURNS INT(11)
BEGIN
    RETURN (SELECT (year(current_date())
           - year(ano)
            - (case
                when month(ano) >  month(current_date()) then 1
                when (month(ano) = month(current_date()) and day(ano) > day(current_date())) then 1
                else 0
               end)));
END