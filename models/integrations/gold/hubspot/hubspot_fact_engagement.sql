{% if false %}

{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}
{{ config(
    database = get_target_database(company),
    alias = 'dim_engagement',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID','SOURCE_SCHEMA']
) }}

SELECT
    ID,
    TYPE,
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_ENGAGEMENT') }} 

{% if company == 'wagway'%} 

UNION ALL 

SELECT
    ID,
    TYPE,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_ENGAGEMENT') }} 
{% endif %}


{% endif %}



