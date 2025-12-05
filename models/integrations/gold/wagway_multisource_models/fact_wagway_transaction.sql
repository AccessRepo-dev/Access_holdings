{{ config(
    database = get_target_database('wagway'),
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
    b.create_stamp AS order_date,
    CONCAT(b.location_id, '-', b.source_db) AS sk_location_id,

    MIN(b.create_stamp) OVER (PARTITION BY b.owner_id) AS acquisition_date,

    DATEDIFF(
        month,
        MIN(b.create_stamp) OVER (PARTITION BY b.owner_id),
        b.create_stamp
    ) AS months_since_acquisition,

    DATEDIFF(
        month,
        LAG(b.create_stamp) OVER (PARTITION BY b.owner_id ORDER BY b.create_stamp),
        b.create_stamp
    ) AS diff_between_orders,

    MAX(b.create_stamp) OVER (PARTITION BY b.owner_id) AS last_order_date,
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
