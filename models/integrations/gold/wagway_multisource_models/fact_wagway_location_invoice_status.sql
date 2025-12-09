{{ config(
    database = get_target_database('wagway'),
    materialized = 'table',
    alias = 'FACT_WAGWAY_LOCATION_INVOICE_STATUS'
) }}

WITH normalized_invoices AS (
    SELECT
        CONCAT(LOCATION_ID, '-', SOURCE_DB) AS sk_location_id,
        LOCATION_ID,
        ID AS invoice_id,
        CASE
            WHEN CANCEL_STAMP IS NOT NULL THEN 'CANCELLED'
            WHEN CONFIRMED_STAMP IS NOT NULL THEN 'CONFIRMED'
            WHEN WAIT_LIST_STAMP IS NOT NULL THEN 'WAITLIST'
            ELSE 'WAITLIST'
        END AS invoice_status,
        COALESCE(
            CANCEL_STAMP,
            CONFIRMED_STAMP,
            WAIT_LIST_STAMP
        ) AS invoice_time
    FROM {{ get_silver_source('wagway', 'gingr_reservations') }}
)

SELECT
    sk_location_id,
    invoice_time AS invoice_timestamp,
    invoice_status,
    COUNT(DISTINCT invoice_id) AS invoice_count
FROM normalized_invoices
WHERE LOCATION_ID > 0
GROUP BY
    sk_location_id,
    invoice_timestamp,
    invoice_status
