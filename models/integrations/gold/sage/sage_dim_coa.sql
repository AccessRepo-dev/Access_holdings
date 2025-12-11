{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('company', 'spotless') in ['spotless', 'amh'] ) }}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}
{{ config(
    enabled = var('sourcesystem','sage') |lower == 'sage' ,
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
        ACCOUNT_NUMBER,
        CLASS_NAME,
        DEPARTMENT_NAME,
        CAST(NULL AS NUMBER) AS SUBSIDIARY_ID,
        CAST(NULL AS VARCHAR) AS SUBSIDIARY_NAME,
        CAST(NULL AS NUMBER) AS ADJUSTMENT_ID,
        CAST(NULL AS VARCHAR) AS ADJUSTMENT_NAME,
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
    
   

    FROM {{ ref('coa_mapping') }} coa
    {% if company == 'spotless' %}
    LEFT JOIN {{ ref('sage_class') }} c ON c.RECORDNO =  coa.CLASS_ID
    {% endif %}
    WHERE dbt_valid_to IS NULL  -- Only get active records from snapshot
)

SELECT * FROM source