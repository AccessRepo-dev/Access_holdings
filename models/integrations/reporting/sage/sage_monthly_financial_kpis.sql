{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'rpt_monthly_financial_kpis'
) }}

with Agg as (

SELECT
    PERIOD_START_DATE ,
    DIM_SUBSIDIARY_ID,
    DIM_DEPARTMENT_ID,
    DIM_CLASS_ID,
    DIM_LOCATION_ID,
    SUM(CASE WHEN a.METRIC_L1 = 'Revenue' THEN AMOUNT ELSE 0 END) AS REV ,
    SUM(CASE WHEN a.METRIC_L1 = 'COGS' THEN AMOUNT ELSE 0 END) AS COGS,
    SUM(CASE WHEN a.METRIC_L1 = 'Field Corporate Expenses' THEN AMOUNT ELSE 0 END) AS FCE,
    SUM(CASE WHEN a.METRIC_L1 = 'Corporate Expenses' THEN AMOUNT ELSE 0 END) AS CE,
    SUM(case when a.Metric_l1 = 'Operating Expenses' then amount else 0 end) as oe,
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
    DIM_LOCATION_ID,
    PERIOD_START_DATE,
    REV * -1 AS REVENUE,
    -1 * (REV + COGS ) AS GROSS_PROFIT,
    -1 * (REV + COGS + FCE + CE + OE + Other) AS EBITDA  
FROM Agg



