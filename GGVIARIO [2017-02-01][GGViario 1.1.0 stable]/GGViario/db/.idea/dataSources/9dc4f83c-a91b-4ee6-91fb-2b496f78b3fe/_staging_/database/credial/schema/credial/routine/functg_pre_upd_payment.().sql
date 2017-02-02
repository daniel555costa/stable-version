CREATE OR REPLACE FUNCTION functg_pre_upd_payment () RETURNS trigger
	LANGUAGE plpgsql
AS $$
    declare
      -- TG_WHEN {BEFORE, AFTER, or INSTEAD OF}
      -- TG_EVENT {INSERT, UPDATE, DELETE, TRUNCATE}
      -- TG_LEVEL {ROW, STATEMENT}

      vNew pagamento;
      vOld pagamento;

      isLiquidado BOOLEAN;

    begin
      if tg_when = 'BEFORE'
        -- AND tg_event = 'UPDATE'
        and new is of (pagamento)
      then
        
        vNew := new;
        vOld := old;
        isLiquidado := (vNew.PAGA_PRESTACAO >= vOld.PAGA_REEMBOLSO);

        -- Se o pagamento for finalizado entao
        if isLiquidado then
          vNew.paga_state := 0;
          vNew.paga_dtdocumentopagamentoreal := now();
          if vNew.paga_partrance = 1 then
            vNew.paga_numdocumentopagamentoreal := 'Pagamento feito em tranche (O ultimo banco tem mais peso)';
          end if;

          new := vNew;
        END IF;
        
        return new;
      END IF;
    end;
  
$$
