{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_chart_of_account',
    unique_key = 'DIM_CHART_OF_ACCOUNT_ID',
    incremental_strategy = 'merge'
) }}

SELECT
        -- Derived Dimension Key
    HASH(a.ID, m.SUBSIDIARY) AS DIM_CHART_OF_ACCOUNT_ID,

    -- Account (Core)
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

    -- Account Display
    a.ACCOUNTSEARCHDISPLAYNAME AS DISPLAY_NAME,
    a.DISPLAYNAMEWITHHIERARCHY AS DISPLAY_NAME_WITH_HIERARCHY,

    -- Subsidiary
    m.SUBSIDIARY AS SUBSIDIARY_ID,
    s.PARENT AS SUBSIDIARY_PARENT_ID,
    s.NAME AS SUBSIDIARY_NAME,
    s.FULLNAME AS SUBSIDIARY_FULL_NAME,

    COALESCE(a.CURRENCY, s.CURRENCY) AS DIM_CURRENCY_ID

FROM {{ get_silver_source(company, 'ACCOUNT') }} as a
LEFT JOIN {{ get_silver_source(company, 'ACCOUNTSUBSIDIARYMAP') }} m ON a.ID = m.ACCOUNT
LEFT JOIN  {{ get_silver_source(company, 'SUBSIDIARY') }} s ON s.ID = m.SUBSIDIARY


   

