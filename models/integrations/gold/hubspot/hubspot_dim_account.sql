{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['hubspot', 'hubspot_pawville'])}}
{{ config(enabled = var('company', 'none') | lower in ['wagway', 'playfly']) }}
{{ config(
    enabled = false,
    database = get_target_database(company),
    alias = 'dim_account',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

SELECT
    ID_DATE_KEY,
    ID as ACCOUNT_ID,
    PROPERTY_NAME AS NAME,
    PROPERTY_COMPANY_TYPE AS TYPE, 
    CAST(NULL AS VARCHAR) AS INDUSTRY,
    PROPERTY_ANNUALREVENUE AS ANNUAL_REVENUE,
    PROPERTY_NUMBEROFEMPLOYEES AS NUMBER_OF_EMPLOYEES,
    PROPERTY_HUBSPOT_OWNER_ID AS OWNER_ID,
    PROPERTY_CITY AS BILLING_CITY, 
    CAST(NULL AS VARCHAR) AS SHIPPING_CITY, -- adding SHIPPING_CITY column to make it consistent with saleforce 
    PROPERTY_CREATEDATE AS CREATED_DATE,
    PROPERTY_HS_LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
    DBT_VALID_FROM, 
    DBT_VALID_TO, 
    IS_ACTIVE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE,



    PROPERTY_DOMAIN AS DOMAIN,
    PROPERTY_PHONE AS PHONE,
    PROPERTY_ADDRESS AS ADDRESS,
    PROPERTY_CITY AS CITY,
    PROPERTY_STATE AS STATE,
    PROPERTY_COUNTRY AS COUNTRY,

    {% if company | lower not in ['amh', 'playfly'] %}
        TRIM(PROPERTY_COMPANY_TYPE) AS PROPERTY_COMPANY_TYPE
    {% endif %}
FROM {{ get_silver_source(company , 'HUBSPOT_COMPANY') }} 