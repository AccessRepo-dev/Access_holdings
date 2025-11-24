
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_chart_of_account_bkp',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID'
) }}

{% set derived_metrics = var('derived_metrics') %}


WITH source AS (
    SELECT
        (HASH(ACCOUNT_ID,LOCATION_ID,DEPARTMENT_ID,PROJECT_ID,CLASS_ID)) AS DIM_CHART_OF_ACCOUNT_ID,        
        ACCOUNT_ID,
        ACCOUNT_NAME,
        CAST(ACCOUNT_NUMBER AS VARCHAR) AS ACCOUNT_NUMBER,
        CAST(NULL AS INT ) SUBSIDIARY_ID,
        CAST(NULL AS VARCHAR ) AS SUBSIDIARY_NAME,
        coa.CLASS_ID,
        CAST(NULL AS INT) AS ADJUSTMENT_ID,
        CAST(coa.CLASS_NAME AS VARCHAR) AS CLASS_NAME,
        PROJECT_ID,
        PROJECT_NAME,
        DEPARTMENT_ID,
        DEPARTMENT_NAME,
        LOCATION_ID,
        LOCATION_NAME,
        CAST(METRIC_L1 AS VARCHAR) AS METRIC_L1,
        CAST(METRIC_L2 AS VARCHAR) AS METRIC_L2,
        CAST(METRIC_L3 AS VARCHAR) AS METRIC_L3,
        CAST(METRIC_L4 AS VARCHAR) AS METRIC_L4,
        CAST(METRIC_L5 AS VARCHAR) AS METRIC_L5,
        CAST(METRIC_L6 AS VARCHAR) AS METRIC_L6,
        CAST(CASH_FLOW_L1 AS VARCHAR) AS CASH_FLOW_L1,
        CAST(CASH_FLOW_L2 AS VARCHAR) AS CASH_FLOW_L2,
        CAST(CASH_FLOW_L3 AS VARCHAR) AS CASH_FLOW_L3,
        CAST(IS_BS AS VARCHAR) AS IS_BS,
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
    FROM {{ get_silver_source(company, company ~ '_COA_MAPPING') }} coa
     {% if company == 'spotless' %}
        LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_CLASS') }} c ON c.RECORDNO =  coa.CLASS_ID
        {% endif %}
    
),

derived_metric_rows AS (
    {% for metric in derived_metrics %}
    SELECT
        CAST({{ -loop.index }} AS VARCHAR) AS DIM_CHART_OF_ACCOUNT_ID,
        NULL AS ACCOUNT_ID,
        NULL AS ACCOUNT_NAME,
        NULL AS ACCOUNT_NUMBER,
        NULL AS SUBSIDIARY_ID,
        NULL AS SUBSIDIARY_NAME,
        NULL AS CLASS_ID,
        NULL AS ADJUSTMENT_ID,
        NULL AS CLASS_NAME,
        NULL AS PROJECT_ID,
        NULL AS PROJECT_NAME,
        NULL AS DEPARTMENT_ID,
        NULL AS DEPARTMENT_NAME,
        NULL AS LOCATION_ID,
        NULL AS LOCATION_NAME,
        '{{ metric }}' AS METRIC_L1,
        CASE WHEN '{{ metric }}' = 'Equity' THEN 'Net Income' ELSE NULL END AS METRIC_L2,
        NULL AS METRIC_L3,
        NULL AS METRIC_L4,
        NULL AS METRIC_L5,
        NULL AS METRIC_L6,
        NULL AS CASH_FLOW_L1,
        NULL AS CASH_FLOW_L2,
        NULL AS CASH_FLOW_L3,
        CASE WHEN '{{ metric }}' IN ('Total Liabilities & Equity','Equity','Total Assets','Total Liabilities') THEN 'BS' ELSE 'IS' END AS  IS_BS,
        NULL AS IS_ADJ,
        NULL AS DEBT_MAPPING
    
    {% if metric == 'Equity' %}
            UNION ALL
            SELECT
                CAST({{ -loop.index }} * 100 - 2 AS NUMBER) AS DIM_CHART_OF_ACCOUNT_ID,
                NULL AS ACCOUNT_ID,
                NULL AS ACCOUNT_NAME,
                NULL AS ACCOUNT_NUMBER,
                NULL AS SUBSIDIARY_ID,
                NULL AS SUBSIDIARY_NAME,
                NULL AS CLASS_ID,
                NULL AS ADJUSTMENT_ID,
                NULL AS PROJECT_ID,
                NULL AS PROJECT_NAME,
                NULL AS CLASS_NAME,
                NULL AS DEPARTMENT_ID,
                NULL AS DEPARTMENT_NAME,
                NULL AS LOCATION_ID,
                NULL AS LOCATION_NAME,
                '{{ metric }}' AS METRIC_L1,
                'Retained Earnings' AS METRIC_L2,
                NULL AS METRIC_L3,
                NULL AS METRIC_L4,
                NULL AS METRIC_L5,
                NULL AS METRIC_L6,
                NULL AS CASH_FLOW_L1,
                NULL AS CASH_FLOW_L2,
                NULL AS CASH_FLOW_L3,
                'BS' AS IS_BS,
                NULL AS IS_ADJ,
                NULL AS DEBT_MAPPING
        {% endif %}

    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
),

final_result AS (
    SELECT * FROM source
    UNION ALL
    SELECT * FROM derived_metric_rows
)

SELECT * FROM final_result




