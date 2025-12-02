{% set company = var('company') %}

{{ config(
    enabled = (var('company') | lower) == 'wagway',
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_AT_RISK_CUSTOMERS'
) }}

WITH base AS (
    SELECT
        b.owner_id,
        a.account_code_id,
        a.source_db,
        a.pos_transaction_id AS invoice_id,
        b.create_stamp AS order_date,

        /* Per owner-account-source first & last invoice */
        MIN(b.create_stamp) OVER (
            PARTITION BY b.owner_id, a.source_db, a.account_code_id
        ) AS min_invoice_date,

        MAX(b.create_stamp) OVER (
            PARTITION BY b.owner_id, a.source_db, a.account_code_id
        ) AS max_invoice_date,

        /* Next invoice for interval calculation */
        LEAD(b.create_stamp) OVER (
            PARTITION BY b.owner_id, a.source_db, a.account_code_id
            ORDER BY b.create_stamp
        ) AS next_invoice_date

    FROM {{ get_silver_source('wagway', 'gingr_pos_transaction_items') }} a
    LEFT JOIN {{ get_silver_source('wagway', 'gingr_pos_transactions') }}  b
        ON CONCAT(a.pos_transaction_id, a.source_db) = CONCAT(b.id, b.source_db)
        AND b.delete_indicator = 0
    LEFT JOIN {{ get_silver_source('wagway', 'gingr_account_codes') }} c
        ON CONCAT(a.account_code_id, a.source_db) = CONCAT(c.id, c.source_db)
        AND c.delete_indicator = 0
    WHERE b.total = b.payment_amount
      AND a.delete_indicator = 0
      AND b.create_stamp >= DATEADD(month, -12, CURRENT_TIMESTAMP)
),

intervals AS (
    SELECT
        owner_id,
        account_code_id,
        source_db,
        invoice_id,
        order_date,
        min_invoice_date,
        max_invoice_date,
        DATEDIFF('day', order_date, next_invoice_date) AS days_until_next_invoice,
        DATEDIFF('day', order_date, CURRENT_DATE()) AS days_since_invoice
    FROM base
),

avg_calc AS (
    SELECT
        owner_id,
        account_code_id,
        source_db,
        AVG(days_until_next_invoice) AS avg_days_between_invoices
    FROM intervals
    WHERE days_until_next_invoice IS NOT NULL
    GROUP BY owner_id, account_code_id, source_db
)

SELECT
    i.owner_id,
    i.account_code_id,
    i.source_db,
    i.invoice_id,
    i.order_date AS invoice_date,
    i.min_invoice_date,
    i.max_invoice_date,
    i.days_until_next_invoice,
    i.days_since_invoice,
    a.avg_days_between_invoices,
    CASE 
        WHEN i.days_since_invoice > a.avg_days_between_invoices THEN TRUE
        ELSE FALSE
    END AS is_at_risk,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS LAST_REFRESH_DATE
FROM intervals i
LEFT JOIN avg_calc a
    ON a.owner_id = i.owner_id
   AND a.account_code_id = i.account_code_id
   AND a.source_db = i.source_db
