CREATE OR REPLACE FUNCTION rule."generateNumClient" () RETURNS character varying
	LANGUAGE plpgsql
AS $$
   declare
      genNumDoss character varying(9);
      ran numeric;
      tt integer;
   begin
      -- retirar aleatoriamente um numero de docier com 9 digitos
      genNumDoss := trim(to_char(random()*999999999, '999999999'));

      -- verificar se algum cliente ja possua esse numero de docierr
      select count(*) into tt
        from credial.dossiercliente dos
        where dos.dos_numdos = genNumDoss;

      if tt != 0 THEN return rule."generateNumClient"(); end if;
      RETURN genNumDoss;
   end;
$$
