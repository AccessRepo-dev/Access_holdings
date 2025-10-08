
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_chart_of_account',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID'
) }}


WITH ACCOUNTDETAILS AS 
(
    SELECT 
        DISTINCT 
        RECORDNO AS ACCOUNT_ID,
        ACCOUNTNO AS ACCOUNT_NUMBER,
        TITLE AS ACCOUNT_TITLE
    FROM {{ get_silver_source(company, 'GL_ACCOUNT') }} 

    UNION

    SELECT 
        DISTINCT
        ACCOUNTKEY AS ACCOUNT_ID,
        ACCOUNTNO AS ACCOUNT_NUMBER,
        ACCOUNTTITLE AS ACCOUNT_TITLE
    FROM {{ get_silver_source(company, 'GL_ENTRY') }} 
  
)
SELECT
    ACCOUNT_ID AS DIM_CHART_OF_ACCOUNT_ID,
    -- Core Identifiers
    ACCOUNT_ID AS ACCOUNT_ID,
    CAST(ACCOUNT_NUMBER AS VARCHAR) AS ACCOUNT_NUMBER,
    ACCOUNT_TITLE AS ACCOUNT_NAME,
    null AS MAIN_ACCOUNT_NAME,
    null AS ACCOUNT_NAME_SUBCATEGORY_1,
    null AS ACCOUNT_NAME_SUBCATEGORY_2,
    null AS ACCOUNT_NAME_SUBCATEGORY_3,
    null AS ACCOUNT_DESCRIPTION,
    CAST(null AS INT) AS ACCOUNT_PARENT_ID,
    NULL AS ACCOUNT_TYPE,
    null AS DISPLAY_NAME,
    null  AS DISPLAY_NAME_WITH_HIERARCHY,
    CAST(null AS INT) AS SUBSIDIARY_ID,
    CAST(null AS INT) AS SUBSIDIARY_PARENT_ID,
    null AS SUBSIDIARY_NAME,
    null AS SUBSIDIARY_FULL_NAME,
     CAST(null AS INT) AS DIM_CURRENCY_ID 
FROM ACCOUNTDETAILS


