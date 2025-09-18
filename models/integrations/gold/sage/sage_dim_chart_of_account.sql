
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ACCOUNT_ID'
) }}


with source as (
    SELECT 

       
        RECORDNO AS DIM_CHART_OF_ACCOUNT_ID,
        -- Core Identifiers
        RECORDNO AS ACCOUNT_ID,
        ACCOUNTNO AS ACCOUNT_NUMBER,
        TITLE AS ACCOUNT_NAME,
        null AS MAIN_ACCOUNT_NAME,
        null AS ACCOUNT_NAME_SUBCATEGORY_1,
        null AS ACCOUNT_NAME_SUBCATEGORY_2,
        null AS ACCOUNT_NAME_SUBCATEGORY_3,
        null AS ACCOUNT_DESCRIPTION,
        null AS ACCOUNT_PARENT_ID,
        ACCOUNTTYPE AS ACCOUNT_TYPE,
        null AS DISPLAY_NAME,
        null  AS DISPLAY_NAME_WITH_HIERARCHY,
        null AS SUBSIDIARY_ID,
        null AS SUBSIDIARY_PARENT_ID,
        null AS SUBSIDIARY_NAME,
        null AS SUBSIDIARY_FULL_NAME,
        null AS DIM_CURRENCY_ID


    FROM {{ get_silver_source(company, 'sage_gl_account') }} 
  
)
SELECT *
FROM source


