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
    CONVERT_TIMEZONE('America/New_York', b.create_stamp) AS order_date,
    CONCAT(b.location_id, '-', b.source_db) AS sk_location_id,

    MIN(CONVERT_TIMEZONE('America/New_York', b.create_stamp)) OVER (PARTITION BY b.owner_id) AS acquisition_date,

    DATEDIFF(
        month,
        MIN(CONVERT_TIMEZONE('America/New_York', b.create_stamp)) OVER (PARTITION BY b.owner_id),
        CONVERT_TIMEZONE('America/New_York', b.create_stamp)
    ) AS months_since_acquisition,

    DATEDIFF(
        month,
        LAG(CONVERT_TIMEZONE('America/New_York', b.create_stamp)) OVER (PARTITION BY b.owner_id ORDER BY CONVERT_TIMEZONE('America/New_York', b.create_stamp)),
        CONVERT_TIMEZONE('America/New_York', b.create_stamp)
    ) AS diff_between_orders,

    MAX(CONVERT_TIMEZONE('America/New_York', b.create_stamp)) OVER (PARTITION BY b.owner_id) AS last_order_date,
    c.code,
    
    CASE
        WHEN d.cancel_stamp IS NOT NULL
            THEN 'Cancelled'
        WHEN d.confirmed_stamp IS NOT NULL
            THEN 'Confirmed'
        WHEN d.wait_list_stamp IS NOT NULL
            THEN 'Waitlisted'
        ELSE 'Waitlisted'
    END AS current_status,

    CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS LAST_REFRESH_DATE
    
FROM {{ ref('gingr_pos_transaction_items') }} a
LEFT JOIN {{ ref('gingr_pos_transactions') }}  b
    ON CONCAT(a.pos_transaction_id, a.source_db) = CONCAT(b.id, b.source_db)
    AND b.delete_indicator = 0
LEFT JOIN {{ ref('gingr_account_codes') }} c
    ON CONCAT(a.account_code_id, a.source_db) = CONCAT(c.id, c.source_db)
    AND c.delete_indicator = 0
LEFT JOIN {{ ref('gingr_reservations') }}
    ON CONCAT(a.pos_transaction_id, a.source_db) = CONCAT(d.id, d.source_db)
    AND d.delete_indicator = 0
WHERE b.total = b.payment_amount
  AND a.delete_indicator = 0
