{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'rpt_monthly_financial_kpis'
) }}


with agg as (
SELECT
    PERIOD_START_DATE ,
    SUM(CASE WHEN a.METRIC_L1 = 'Revenue' THEN AMOUNT ELSE 0 END) AS REVENUE ,
    SUM(CASE WHEN a.METRIC_L1 = 'COGS' THEN AMOUNT ELSE 0 END) AS COGS,
    SUM(CASE WHEN a.METRIC_L1 = 'Field Corporate Expenses' THEN AMOUNT ELSE 0 END) AS FCE,
    SUM(CASE WHEN a.METRIC_L1 = 'Post Corporate EBITDA' THEN AMOUNT ELSE 0 END) AS PCE,
    SUM(CASE WHEN a.METRIC_L1 = 'Other (Income) / Expense' THEN AMOUNT ELSE 0 END) AS Other
FROM {{ ref('netsuite_fact_transaction') }} f
    LEFT JOIN  {{ ref('netsuite_dim_coa') }} a
    ON f.DIM_CHART_OF_ACCOUNT_ID = a.DIM_CHART_OF_ACCOUNT_ID
    GROUP BY PERIOD_START_DATE
)

SELECT 
    PERIOD_START_DATE,
    REVENUE,
    -1 * (REVENUE + COGS ) AS GROSS_PROFIT,
    REVENUE + COGS + FCE + PCE + Other AS EBITDA  
FROM Agg




