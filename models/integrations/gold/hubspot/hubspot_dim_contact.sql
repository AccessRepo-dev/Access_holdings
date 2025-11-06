{% set company = var('company') %}

{{ config(
    database = get_target_database(company),
    alias = 'dim_contact',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID','SOURCE_SCHEMA']
) }}

SELECT
    ID,
    PROPERTY_FIRSTNAME AS FIRST_NAME,
    PROPERTY_LASTNAME AS LAST_NAME,
    PROPERTY_EMAIL AS EMAIL,
    PROPERTY_PHONE AS PHONE,
    PROPERTY_MOBILEPHONE AS MOBILE_PHONE,
    PROPERTY_LIFECYCLESTAGE AS LIFECYCLE_STAGE,
    PROPERTY_HUBSPOT_OWNER_ID AS OWNER_ID,
    'HUBSPOT' AS SOURCE_SCHEMA


FROM {{ get_silver_source(company , 'HUBSPOT_CONTACT') }} 


{% if company == 'wagway'%} 
UNION ALL 

SELECT
    ID,
    PROPERTY_FIRSTNAME AS FIRST_NAME,
    PROPERTY_LASTNAME AS LAST_NAME,
    PROPERTY_EMAIL AS EMAIL,
    PROPERTY_PHONE AS PHONE,
    PROPERTY_MOBILEPHONE AS MOBILE_PHONE,
    PROPERTY_LIFECYCLESTAGE AS LIFECYCLE_STAGE,
    PROPERTY_HUBSPOT_OWNER_ID AS OWNER_ID,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_CONTACT') }} 
{% endif %}







