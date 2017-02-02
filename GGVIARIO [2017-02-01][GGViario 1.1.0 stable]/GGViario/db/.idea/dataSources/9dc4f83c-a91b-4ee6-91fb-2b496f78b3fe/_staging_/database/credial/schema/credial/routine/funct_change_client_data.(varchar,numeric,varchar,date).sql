CREATE or REPLACE FUNCTION funct_change_client_data (userid character varying, idagencia numeric, clientnif character varying, datanascimento date) RETURNS result
	LANGUAGE plpgsql
AS $$

  DECLARE
    vDossierCliente dossiercliente;
    res result;
  BEGIN
    SELECT * into vDossierCliente
      from dossiercliente dos
      where dos.dos_nif = clientnif;

    if vDossierCliente.dos_dtnasc is not null then
      res.result := FALSE;
      res.message := credial.message('cannot-update-clinete-date');
      RETURN res;
    ELSE
      UPDATE dossiercliente
        set dos_dtnasc = dataNascimento
        where dos_nif = clientnif;

      RETURN  '(true,success)'::result;
    END IF;
  END;
$$
