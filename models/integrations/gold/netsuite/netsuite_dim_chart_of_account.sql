{% set company = var('company', 'Unknown company') | lower %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'netsuite',
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_chart_of_account',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID',
    incremental_strategy = 'merge'
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
    'Total Liabilities',
    'Lender EBITDA',
    'Pro-Forma EBITDA',
    'Lender Adjustments',
    'Pro-Forma Adjustments'
] %}

WITH source AS (
    SELECT
        HASH(a.ID, m.SUBSIDIARY, tl.CLASS) AS DIM_CHART_OF_ACCOUNT_ID,
        a.ID AS ACCOUNT_ID,
        a.ACCTNUMBER AS ACCOUNT_NUMBER,
        a.FULLNAME AS ACCOUNT_NAME,
        a.MAIN_ACCOUNT_NAME,
        a.ACCOUNT_NAME_SUBCATEGORY_1,
        a.ACCOUNT_NAME_SUBCATEGORY_2,
        a.ACCOUNT_NAME_SUBCATEGORY_3,
        a.DESCRIPTION AS ACCOUNT_DESCRIPTION,
        a.PARENT AS ACCOUNT_PARENT_ID,
        a.ACCTTYPE AS ACCOUNT_TYPE,
        a.ACCOUNTSEARCHDISPLAYNAME AS DISPLAY_NAME,
        a.DISPLAYNAMEWITHHIERARCHY AS DISPLAY_NAME_WITH_HIERARCHY,
        m.SUBSIDIARY AS DIM_SUBSIDIARY_ID,
        tl.CLASS AS DIM_CLASS_ID,
        COALESCE(a.CURRENCY, s.CURRENCY) AS DIM_CURRENCY_ID,
        CAST(NULL AS INT) AS DIM_LOCATION_ID,
        CAST(NULL AS INT) AS DIM_DEPARTMENT_ID,
        CAST(NULL AS INT) AS DIM_PROJECT_ID,
        map.METRIC_L1,
        map.METRIC_L2,
        map.METRIC_L3,
        CAST(map.METRIC_L4 AS STRING) AS METRIC_L4,
        CAST(map.METRIC_L5 AS STRING) AS METRIC_L5,
        CAST(map.METRIC_L6 AS STRING) AS METRIC_L6
    FROM {{ get_silver_source(company, 'ACCOUNT') }} AS a
    LEFT JOIN {{ get_silver_source(company, 'ACCOUNTSUBSIDIARYMAP') }} AS m
        ON a.ID = m.ACCOUNT
    LEFT JOIN {{ get_silver_source(company, 'SUBSIDIARY') }} AS s
        ON s.ID = m.SUBSIDIARY
    LEFT JOIN (
        SELECT DISTINCT
            tal.ACCOUNT,
            tl.SUBSIDIARY,
            tl.CLASS
        FROM {{ get_silver_source(company, 'TRANSACTIONLINE') }} tl
        LEFT JOIN {{ get_silver_source(company, 'TRANSACTIONACCOUNTINGLINE') }} tal
            ON tl.TRANSACTION = tal.TRANSACTION
            AND tl.ID = tal.TRANSACTIONLINE
        WHERE tl.CLASS IS NOT NULL
    ) AS tl
        ON tl.ACCOUNT = a.ID AND tl.SUBSIDIARY = m.SUBSIDIARY
    LEFT JOIN {{ get_silver_source(company, company ~ '_COA_MAPPING') }} AS map
        ON ABS(HASH(a.ID, m.SUBSIDIARY, tl.CLASS)) = ABS(HASH(map.ACCOUNT_ID, map.SUBSIDIARY_ID, map.CLASS_ID))
),

derived_metric_rows AS (
    {% for metric in derived_metrics %}
    SELECT
        CAST({{ -loop.index }} AS VARCHAR) AS DIM_CHART_OF_ACCOUNT_ID,
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
        CAST(NULL AS NUMBER) AS DIM_CLASS_ID,
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

final_result AS (
    SELECT * FROM source
    UNION ALL
    SELECT * FROM derived_metric_rows
)

SELECT * FROM final_result