{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    enabled = false,
    database = get_target_database(company),
    alias = 'dim_owner',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['OWNER_ID','SOURCE_SCHEMA']
) }}

SELECT
    OWNER_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_OWNER') }} 

{% if company == 'wagway'%} 

UNION ALL 

SELECT
    OWNER_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_OWNER') }} 
{% endif %}