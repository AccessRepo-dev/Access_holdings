{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'rpt_transaction_summary'
) }}


SELECT
    DIM_SUBSIDIARY_ID,
    DIM_DEPARTMENT_ID,
    DIM_LOCATION_ID,
    DIM_CLASS_ID,
    DIM_ITEM_ID,
    DIM_PROJECT_ID,
    DIM_ADDBACK_ID,
    DIM_CHART_OF_ACCOUNT_ID,
    ACCOUNT_NUMBER,
    ACCOUNT_NAME,
    ACCOUNT_TYPE,
    DIM_PERIOD_ID,
    MAX(PERIOD_START_DATE) AS PERIOD_START_DATE,
    SUM(NETAMOUNT) AS TOTAL_NET_AMOUNT,
    SUM(AMOUNT) AS AMOUNT,
    SUM(CONVERTED_NET_AMOUNT) AS TOTAL_CONVERTED_NET_AMOUNT,
    SUM(BOM_QUANTITY) AS TOTAL_BOM_QUANTITY,
    SUM(QUANTITY) AS TOTAL_QUANTITY

FROM {{ get_gold_source(company, 'FACT_TRANSACTION') }}
GROUP BY
    ALL