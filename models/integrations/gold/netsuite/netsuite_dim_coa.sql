{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(
    enabled = var('sourcesystem') |lower == 'netsuite' ,
    database = get_target_database(company),
    alias = 'dim_chart_of_account',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID',
) }}

WITH source AS (
    SELECT
        COA_ID AS DIM_CHART_OF_ACCOUNT_ID,
        ACCOUNT_ID,
        SUBSIDIARY_ID,
        CLASS_ID,
        LOCATION_ID,
        DEPARTMENT_ID,
   
        ADJUSTMENT_ID,
        
        LOCATION_NAME,
        SUBSIDIARY_NAME,
        ACCOUNT_NAME,
        ACCOUNT_NUMBER,
        CLASS_NAME,
        DEPARTMENT_NAME,
        ADJUSTMENT_NAME,
      
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
        DEBT_MAPPING,
        
  
        CASE WHEN COALESCE(ADJUSTMENT_ID,0) <> 0 THEN 1 
            ELSE 0
        END AS IS_ADJ
      

    FROM {{ get_silver_source(company, sourcesystem ~ '_coa') }}
    WHERE dbt_valid_to IS NULL  -- Only get active records from snapshot
)

SELECT * FROM source