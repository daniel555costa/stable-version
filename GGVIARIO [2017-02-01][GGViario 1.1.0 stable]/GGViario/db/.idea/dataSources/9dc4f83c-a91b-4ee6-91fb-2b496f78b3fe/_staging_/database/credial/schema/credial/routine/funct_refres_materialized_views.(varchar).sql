CREATE or REPLACE FUNCTION funct_refres_materialized_views (materialview character varying) RETURNS result
	LANGUAGE plpgsql
AS $$
  DECLARE
    CLIENT CONSTANT CHARACTER VARYING DEFAULT 'CLIENT';
    PAYMENT CONSTANT CHARACTER VARYING DEFAULT 'PAYMENT';
    CREDIT CONSTANT CHARACTER VARYING DEFAULT 'CREDIT';
  BEGIN

    CASE materialView

      WHEN  CLIENT THEN
        REFRESH MATERIALIZED VIEW filter.mver_client_documento;

      WHEN PAYMENT THEN
        REFRESH MATERIALIZED VIEW filter.mver_client_documento;

      WHEN CREDIT THEN
        REFRESH MATERIALIZED VIEW filter.mver_client_simple;
        REFRESH MATERIALIZED VIEW filter.mver_client_documento; -- corresponde ao pagamento
        REFRESH MATERIALIZED VIEW filter.mver_client_documento_entreges;
        REFRESH MATERIALIZED VIEW filter.mver_client_garantias;

      ELSE
        REFRESH MATERIALIZED VIEW filter.mver_client_simple;
        REFRESH MATERIALIZED VIEW filter.mver_client_documento; -- corresponde ao pagamento
        REFRESH MATERIALIZED VIEW filter.mver_client_documento_entreges;
        REFRESH MATERIALIZED VIEW filter.mver_client_garantias;

    END CASE;

    RETURN '(true,Sucesso)'::result;

  END;
$$
