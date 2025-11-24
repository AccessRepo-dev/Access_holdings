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
        {%if company == 'wagway'%}
            ADJUSTMENT_ID,
        {%else%}
            0 AS ADJUSTMENT_ID,
        {%endif%}
        LOCATION_NAME,
        SUBSIDIARY_NAME,
        ACCOUNT_NAME,
        ACCOUNT_NUMBER,
        CLASS_NAME,
        DEPARTMENT_NAME,
        {%if company == 'wagway'%}
            ADJUSTMENT_NAME,
        {%else%}
            'Unknown' AS ADJUSTMENT_NAME,
        {%endif%}
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
        
        {% if company == 'wagway'%}
        CASE WHEN ADJUSTMENT_ID <> 0 THEN 1 
            ELSE 0
        END AS IS_ADJ
        {% else %}
        CAST(NULL AS INT) AS IS_ADJ
        {% endif %}

    FROM {{ get_silver_source(company, sourcesystem ~ '_coa') }}
    WHERE dbt_valid_to IS NULL  -- Only get active records from snapshot
)

SELECT * FROM source