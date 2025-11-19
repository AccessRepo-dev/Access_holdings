{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(
    enabled = var('sourcesystem') |lower == 'sage' ,
    database = get_target_database(company),
    alias = 'dim_chart_of_account',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID',
) }}

WITH source AS (
    SELECT
        COA_ID AS DIM_CHART_OF_ACCOUNT_ID,
        ACCOUNT_ID,
        PROJECT_ID,
        CLASS_ID,
        LOCATION_ID,
        DEPARTMENT_ID,
        LOCATION_NAME,
        PROJECT_NAME,
        ACCOUNT_NAME,
        CLASS_NAME,
        DEPARTMENT_NAME,
        METRIC_L1,
        METRIC_L2,
        METRIC_L3,
        METRIC_L4,
        METRIC_L5,
        METRIC_L6,
        CASHFLOW_L1 AS CASH_FLOW_L1,
        CASHFLOW_L2 AS CASH_FLOW_L2,
        CASHFLOW_L3 AS CASH_FLOW_L3,
        IS_BS,
        CASE WHEN 
        {% if company == 'spotless' %}
        c.PARENTKEY IN (18,28) 
        {% elif company == 'amh'%}
        CLASS_ID IN (1)
        {% endif %}
        THEN 1
        ELSE 0 
        END AS IS_ADJ,
        DEBT_MAPPING
    
   

    FROM {{ get_silver_source(company, sourcesystem ~ '_coa') }} coa
    {% if company == 'spotless' %}
    LEFT JOIN {{ get_silver_source(company, 'CLASS') }} c ON c.RECORDNO =  coa.CLASS_ID
    {% endif %}
    WHERE dbt_valid_to IS NULL  -- Only get active records from snapshot
)

SELECT * FROM source