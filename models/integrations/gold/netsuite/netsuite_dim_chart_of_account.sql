{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    unique_key = 'DIM_ACCOUNT_ID',
    incremental_strategy = 'merge'
) }}

WITH flattened_accounts AS (
    SELECT 
        a.DESCRIPTION AS ACCOUNT_DESCRIPTION,
        a.LOCATION AS LOCATION_ID,
        a.ID AS ACCOUNT_ID,
        a.FULLNAME AS ACCOUNT_NAME,
        a.MAIN_ACCOUNT_NAME,
        a.ACCOUNT_NAME_SUBCATEGORY_1,
        a.ACCOUNT_NAME_SUBCATEGORY_2,
        a.ACCOUNT_NAME_SUBCATEGORY_3,
        a.ACCTNUMBER AS ACCOUNT_NUMBER,
        a.PARENT AS ACCOUNT_PARENT_ID,
        CAST(f.value AS INT) AS ACCOUNT_SUBSIDIARY_ID,
        a.ACCTTYPE AS ACCOUNT_TYPE,
        a.CLASS AS CLASS_ID,
        a.DEPARTMENT AS DEPARTMENT_ID,
        a.ACCOUNTSEARCHDISPLAYNAME AS DISPLAY_NAME,
        a.DISPLAYNAMEWITHHIERARCHY AS DISPLAY_NAME_WITH_HIERARCHY,
        a.CURRENCY AS CURRENCY_ID
     FROM {{ get_silver_source(company, 'netsuite_account') }} a,
         LATERAL FLATTEN(input => SPLIT(a.SUBSIDIARY, ',')) f
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'ACCOUNT_ID',
        'ACCOUNT_SUBSIDIARY_ID',
        'CLASS_ID',
        'DEPARTMENT_ID'
    ]) }} AS DIM_ACCOUNT_ID,   -- surrogate key
    ea.ACCOUNT_ID,             -- natural key
    ea.ACCOUNT_NAME,
    ea.MAIN_ACCOUNT_NAME,
    ea.ACCOUNT_NAME_SUBCATEGORY_1,
    ea.ACCOUNT_NAME_SUBCATEGORY_2,
    ea.ACCOUNT_NAME_SUBCATEGORY_3,    
    ea.ACCOUNT_NUMBER,
    ea.ACCOUNT_DESCRIPTION,
    ea.ACCOUNT_PARENT_ID,
    ea.ACCOUNT_SUBSIDIARY_ID,
    ea.LOCATION_ID,
    ea.ACCOUNT_TYPE,
    ea.CLASS_ID,
    ea.DEPARTMENT_ID,
    ea.DISPLAY_NAME,
    ea.DISPLAY_NAME_WITH_HIERARCHY,
    COALESCE(ea.CURRENCY_ID, s.CURRENCY) AS CURRENCY_ID,
    s.PARENT AS SUBSIDIARY_PARENT_ID,
    s.FULLNAME AS SUBSIDIARY_FULL_NAME,
    s.NAME AS SUBSIDIARY_NAME,
    c.FULLNAME AS CLASS_FULL_NAME,
    c.NAME AS CLASS_NAME,
    c.PARENT AS CLASSIFICATION_PARENT
FROM flattened_accounts as ea
LEFT JOIN  {{ get_silver_source(company, 'netsuite_subsidiary') }} s
    ON ea.ACCOUNT_SUBSIDIARY_ID = s.id
LEFT JOIN  {{ get_silver_source(company, 'netsuite_classification') }} c 
    ON ea.CLASS_ID = c.ID
