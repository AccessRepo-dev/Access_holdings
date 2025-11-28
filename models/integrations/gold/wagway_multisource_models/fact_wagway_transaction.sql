{% set company = var('company') %}

{{ config(
    enabled = (var('company') | lower) == 'wagway',
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_TRANSACTION'
) }}

SELECT
    a.pos_transaction_id AS invoice_id,
    a.source_db,
    a.price AS service_price,
    a.account_code_id,
    b.owner_id,
    b.total,
    b.payment_amount,
    TO_TIMESTAMP(b.create_stamp) AS order_date,
    CONCAT(b.location_id, '-', b.source_db) AS sk_location_id,

    MIN(TO_TIMESTAMP(b.create_stamp)) OVER (PARTITION BY b.owner_id) AS acquisition_date,

    DATEDIFF(
        month,
        MIN(TO_TIMESTAMP(b.create_stamp)) OVER (PARTITION BY b.owner_id),
        TO_TIMESTAMP(b.create_stamp)
    ) AS months_since_acquisition,

    DATEDIFF(
        month,
        LAG(TO_TIMESTAMP(b.create_stamp)) OVER (PARTITION BY b.owner_id ORDER BY TO_TIMESTAMP(b.create_stamp)),
        TO_TIMESTAMP(b.create_stamp)
    ) AS diff_between_orders,

    MAX(TO_TIMESTAMP(b.create_stamp)) OVER (PARTITION BY b.owner_id) AS last_order_date,
    c.code,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS LAST_REFRESH_DATE
    
FROM {{ get_silver_source('wagway', 'gingr_pos_transaction_items') }} a
LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transactions') }}  b
    ON CONCAT(a.pos_transaction_id, a.source_db) = CONCAT(b.id, b.source_db)
    AND b.delete_indicator = 0
LEFT JOIN {{ get_silver_source('wagway', 'gingr_account_codes') }} c
    ON CONCAT(a.account_code_id, a.source_db) = CONCAT(c.id, c.source_db)
    AND c.delete_indicator = 0
WHERE b.total = b.payment_amount
  AND a.delete_indicator = 0
