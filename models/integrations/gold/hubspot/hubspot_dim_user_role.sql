{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') == 'hubspot') }}
{{ config(
    database = get_target_database(company),
    alias = 'dim_user_role',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID','SOURCE_SCHEMA']
) }}

SELECT
    ID,
    NAME AS ROLE_NAME,
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_ROLE') }} u

{% if company == 'wagway'%} 

UNION ALL 

SELECT
    ID,
    NAME AS ROLE_NAME,
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_ROLE') }} u
{% endif %}

