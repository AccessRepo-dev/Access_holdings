{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') == 'hubspot') }}
{{ config(
    database = get_target_database(company),
    alias = 'dim_company',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID']
) }}

SELECT
    ID,
    PROPERTY_NAME AS NAME,
    PROPERTY_DOMAIN AS DOMAIN,
    PROPERTY_PHONE AS PHONE,
    PROPERTY_INDUSTRY AS INDUSTRY,
    PROPERTY_ADDRESS AS ADDRESS,
    PROPERTY_CITY AS CITY,
    PROPERTY_STATE AS STATE,
    PROPERTY_COUNTRY AS COUNTRY,
    PROPERTY_HUBSPOT_OWNER_ID AS OWNER_ID,
    PROPERTY_CREATEDATE AS CREATE_DATE,
    PROPERTY_HS_LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,

    {% if company | lower not in ['amh', 'playfly'] %}
        TRIM(PROPERTY_COMPANY_TYPE) AS PROPERTY_COMPANY_TYPE,
    {% endif %}

    --PROPERTY_COMPANY_TYPE AS TYPE,
    PROPERTY_ANNUALREVENUE AS ANNUAL_REVENUE,
    PROPERTY_NUMBEROFEMPLOYEES AS NUMBER_OF_EMPLOYEES
FROM {{ get_silver_source(company , 'HUBSPOT_COMPANY') }} 




