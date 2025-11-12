{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}
{{ config(
    database = get_target_database(company),
    alias = 'dim_user',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID','SOURCE_SCHEMA']
) }}

SELECT
    ID,
    CONCAT(FIRST_NAME,LAST_NAME) AS NAME ,
    ROLE_ID,
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_USERS') }} u

{% if company == 'wagway'%} 

UNION ALL 

SELECT
     ID,
    CONCAT(FIRST_NAME,LAST_NAME) AS NAME ,
    ROLE_ID,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_USERS') }} u
{% endif %}

