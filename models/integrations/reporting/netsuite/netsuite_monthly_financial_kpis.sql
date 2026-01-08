-- {% set company = var('company', 'wagway') | lower %}
-- {{ config(enabled = var('sourcesystem', 'netsuite') == 'netsuite') }}

-- {{ config(
--     database = get_target_database(company),
--     materialized = 'table',
--     alias = 'rpt_transaction_summary'
-- ) }}


-- SELECT
--     DIM_PERIOD_ID,
--     PERIOD_START_DATE ,
--     CASE WHEN a.METRIC_L1 = 'Revue' ,
--     SUM(AMOUNT) AS AMOUNT,
--     SUM(CONVERTED_NET_AMOUNT) AS TOTAL_CONVERTED_NET_AMOUNT,
--     SUM(BOM_QUANTITY) AS TOTAL_BOM_QUANTITY,
--     SUM(QUANTITY) AS TOTAL_QUANTITY

-- FROM {{ ref('netsuite_fact_transaction') }} f
-- LEFT JOIN  {{ ref('netsuite_dim_chart_of_account') }} a
-- ON f.DIM_CHART_OF_ACCOUNT_ID = a.DIM_CHART_OF_ACCOUNT_ID
-- GROUP BY
--     ALL