{% set company = var('company', 'zeus') | lower %}
{% set sourcesystem = var('sourcesystem', 'sedona') | lower %}
{{ config(enabled = var('sourcesystem', 'sedona') == 'sedona') }}

{{ config(
    database = get_target_database(company),
    schema = 'gold',
    materialized = 'table',
    alias = 'rpt_monthly_financial_kpis'
) }}

with Agg as (
SELECT
    PERIOD_START_DATE ,
    DIM_SUBSIDIARY_ID,
    DIM_DEPARTMENT_ID,
    DIM_CLASS_ID,
    NULL AS state_key,
    SUM(CASE WHEN a.METRIC_L1 = 'Revenue' THEN AMOUNT ELSE 0 END) AS REVENUE ,
    SUM(CASE WHEN a.METRIC_L1 = 'COGS' THEN AMOUNT ELSE 0 END) AS COGS,
    SUM(CASE WHEN a.METRIC_L1 = 'Field Corporate Expenses' THEN AMOUNT ELSE 0 END) AS FCE,
    SUM(CASE WHEN a.METRIC_L1 = 'Post Corporate EBITDA' THEN AMOUNT ELSE 0 END) AS PCE,
    SUM(CASE WHEN a.METRIC_L1 = 'Other (Income) / Expense' THEN AMOUNT ELSE 0 END) AS Other
FROM {{database}}.GOLD.FACT_TRANSACTION f
    LEFT JOIN {{database}}.GOLD.DIM_CHART_OF_ACCOUNT  a
    ON f.DIM_CHART_OF_ACCOUNT_ID = a.DIM_CHART_OF_ACCOUNT_ID
    GROUP BY ALL
)

SELECT 
    DIM_SUBSIDIARY_ID,
    DIM_DEPARTMENT_ID,
    DIM_CLASS_ID,
    STATE_KEY,
    PERIOD_START_DATE,
    REVENUE,
    -1 * (REVENUE + COGS ) AS GROSS_PROFIT,
    REVENUE + COGS + FCE + PCE + Other AS EBITDA  
FROM Agg




