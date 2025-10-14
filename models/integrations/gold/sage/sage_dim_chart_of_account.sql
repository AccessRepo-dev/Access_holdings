
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_chart_of_account',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID'
) }}

{% set derived_metrics = var('derived_metrics') %}


WITH source AS (
    SELECT
        (HASH(ACCOUNT_ID,LOCATION_ID,DEPARTMENT_ID,PROJECT_ID)) AS DIM_CHART_OF_ACCOUNT_ID,
        ACCOUNT_ID,
        ACCOUNT_NAME,
        ACCOUNT_NUMBER,
        CAST(NULL AS INT ) SUBSIDIARY_ID,
        NULL AS SUBSIDIARY_NAME,
        CAST(NULL AS INT ) CLASS_ID,
        NULL AS CLASS_NAME,
        PROJECT_ID,
        PROJECT_NAME,
        DEPARTMENT_ID,
        DEPARTMENT_NAME,
        LOCATION_ID,
        LOCATION_NAME,
        METRIC_L1,
        METRIC_L2,
        METRIC_L3,
        METRIC_L4,
        METRIC_L5,
        METRIC_L6
    FROM {{ get_silver_source(company, company ~ '_COA_MAPPING') }}
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
        NULL AS METRIC_L6
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




