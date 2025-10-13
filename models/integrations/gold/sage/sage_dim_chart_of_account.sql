
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_chart_of_account',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID'
) }}

{% set derived_metrics = [
    'Gross Profit',
    'Gross Margin',
    'EBITDA',
    'EBITDA Margin',
    'Field EBITDA',
    'Field EBITDA Margin',
    'Post Corporate EBITDA',
    'Post Corporate EBITDA Margin',
    'Net Income',
    'Adjusted EBITDA',
    'Adjustments',
    'Total Liabilities & Equity',
    'Equity',
    'Total Assets',
    'Total Liabilities'
] %}

WITH ACCOUNTDETAILS AS 
(
    (SELECT 
        DISTINCT 
        RECORDNO AS ACCOUNT_ID,
        ACCOUNTNO AS ACCOUNT_NUMBER,
        TITLE AS ACCOUNT_TITLE,
        CAST(NULL AS INT) AS DIM_LOCATION_ID,
        CAST(NULL AS INT) AS DIM_DEPARTMENT_ID,
        CAST(NULL AS INT) AS DIM_PROJECT_ID
    FROM {{ get_silver_source(company, 'GL_ACCOUNT') }} 
    WHERE RECORDNO NOT IN (SELECT DISTINCT ACCOUNTKEY FROM {{ get_silver_source(company, 'GL_ENTRY') }})
    )
    UNION

    SELECT 
        DISTINCT
        ACCOUNTKEY AS ACCOUNT_ID,
        ACCOUNTNO AS ACCOUNT_NUMBER,
        ACCOUNTTITLE AS ACCOUNT_TITLE,
        LOCATIONKEY AS DIM_LOCATION_ID,
        DEPARTMENTKEY AS DIM_DEPARTMENT_ID,
        PROJECTDIMKEY AS DIM_PROJECT_ID
    FROM {{ get_silver_source(company, 'GL_ENTRY') }} 
  
),
mapped as (
    SELECT
    {% if company == 'spotless'  %}
        ABS(HASH(A.ACCOUNT_ID, A.DIM_LOCATION_ID,A.DIM_DEPARTMENT_ID,A.DIM_PROJECT_ID)) AS DIM_CHART_OF_ACCOUNT_ID,
    {% else %}
        ABS(HASH(A.ACCOUNT_ID, A.DIM_LOCATION_ID,A.DIM_DEPARTMENT_ID,A.DIM_PROJECT_ID))  AS DIM_CHART_OF_ACCOUNT_ID,
    {% endif%}
    -- Core Identifiers
    A.ACCOUNT_ID AS ACCOUNT_ID,
    CAST(A.ACCOUNT_NUMBER AS VARCHAR) AS ACCOUNT_NUMBER,
    A.ACCOUNT_TITLE AS ACCOUNT_NAME,
    null AS MAIN_ACCOUNT_NAME,
    null AS ACCOUNT_NAME_SUBCATEGORY_1,
    null AS ACCOUNT_NAME_SUBCATEGORY_2,
    null AS ACCOUNT_NAME_SUBCATEGORY_3,
    null AS ACCOUNT_DESCRIPTION,
    CAST(null AS INT) AS ACCOUNT_PARENT_ID,
    NULL AS ACCOUNT_TYPE,
    null AS DISPLAY_NAME,
    null  AS DISPLAY_NAME_WITH_HIERARCHY,
    CAST(null AS INT) AS DIM_SUBSIDIARY_ID,
    CAST(null AS INT) AS DIM_CURRENCY_ID,
    A.DIM_LOCATION_ID,
    A.DIM_DEPARTMENT_ID,
    A.DIM_PROJECT_ID,
    map.METRIC_L1,
    map.METRIC_L2,
    map.METRIC_L3,
     CAST(map.METRIC_L4 AS STRING) AS METRIC_L4,
    CAST(map.METRIC_L4 AS STRING) AS METRIC_L5,
    CAST(map.METRIC_L4 AS STRING) AS METRIC_L6
FROM ACCOUNTDETAILS AS A 
LEFT JOIN {{ get_silver_source(company, company ~ '_COA_MAPPING') }} map
    ON
    {% if company == 'spotless'  %}
            ABS(HASH(A.ACCOUNT_ID, A.DIM_LOCATION_ID)) = ABS(HASH(map.ACCOUNT_ID, map.LOCATION_ID))

    {% else %}
            A.ACCOUNT_ID  = map.ACCOUNT_ID  AND  
            COALESCE(A.DIM_LOCATION_ID ,0)  = COALESCE(map.LOCATION_ID,0)  AND 
            COALESCE(A.DIM_DEPARTMENT_ID ,0 )= COALESCE(map.DEPARTMENT_ID ,0) AND 
            COALESCE(A.DIM_PROJECT_ID ,0)= COALESCE(map.PROJECT_ID ,0)
    {% endif%}  

),

derived_metric_rows as (
    {% for metric in derived_metrics %}
    SELECT
        CAST({{ -loop.index }} AS VARCHAR) AS DIM_CHART_OF_ACCOUNT_ID,  -- Negative integers for uniqueness
        CAST(NULL AS NUMBER) AS ACCOUNT_ID,
        NULL AS ACCOUNT_NUMBER,
        NULL AS ACCOUNT_NAME,
        NULL AS MAIN_ACCOUNT_NAME,
        NULL AS ACCOUNT_NAME_SUBCATEGORY_1,
        NULL AS ACCOUNT_NAME_SUBCATEGORY_2,
        NULL AS ACCOUNT_NAME_SUBCATEGORY_3,
        NULL AS ACCOUNT_DESCRIPTION,
        CAST(NULL AS NUMBER) AS ACCOUNT_PARENT_ID,
        NULL AS ACCOUNT_TYPE,
        NULL AS DISPLAY_NAME,
        NULL AS DISPLAY_NAME_WITH_HIERARCHY,
        CAST(NULL AS NUMBER) AS DIM_SUBSIDIARY_ID,
        CAST(NULL AS NUMBER) AS DIM_CURRENCY_ID,
        CAST(NULL AS INT) AS DIM_LOCATION_ID,
        CAST(NULL AS INT) AS DIM_DEPARTMENT_ID,
        CAST(NULL AS INT) AS DIM_PROJECT_ID,
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

-- Final union of actual data and derived metrics
final_result as (
    SELECT * FROM mapped
    UNION ALL
    SELECT * FROM derived_metric_rows
)

SELECT * FROM final_result



