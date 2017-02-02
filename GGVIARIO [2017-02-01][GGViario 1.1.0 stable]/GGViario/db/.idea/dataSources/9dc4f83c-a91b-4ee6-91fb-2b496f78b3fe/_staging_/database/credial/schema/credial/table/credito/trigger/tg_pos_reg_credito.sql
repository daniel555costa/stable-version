DROP TRIGGER tg_pos_reg_credito;
CREATE TRIGGER tg_pos_reg_credito
AFTER INSERT ON credito
FOR EACH ROW EXECUTE PROCEDURE functg_pos_reg_credito()