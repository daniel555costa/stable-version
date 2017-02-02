CREATE OR REPLACE FUNCTION functg_pos_reg_credito () RETURNS trigger
	LANGUAGE plpgsql
AS $$
  declare
    -- TG_WHEN {BEFORE, AFTER, or INSTEAD OF}
    -- TG_EVENT {INSERT, UPDATE, DELETE, TRUNCATE}
    -- TG_LEVEL {ROW, STATEMENT}
    
    vNew credito;
    vCheque chequempresa;

  begin
    if TG_WHEN = 'AFTER'
      -- and TG_EVENT = 'INSERT'
      and new is of (credito)
    then

      vNew := new;
      
      /**
         Quando a requisicao for eliminada siginifica que o cheque foi utilizado em um credito
         Nesse caso depois de eliminar a requisicao deve:
         Diminuir o verdadeiro saldo da conta bancaria
      */
      
      -- carregar as informacoes de cheque empresa
      select * into vCheque
        from chequempresa ch
        where ch.cheq_id = vNew.credi_cheq_id;
      
      -- Incrementar os cheques destribuidos e fechara a carteira caso o cheque ja se thenha acabado
      update chequempresa
        set cheq_state = (
          case 
            when cheq_total = vCheque.cheq_distribuido + 1 then 0
            else cheq_state
          end
        )
        where cheq_id = vCheque.cheq_id;

      RETURN null;
    end if;
  end;
$$
