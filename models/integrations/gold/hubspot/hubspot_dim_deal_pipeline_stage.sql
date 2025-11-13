{% if false %}

{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}
{{ config(
    database = get_target_database(company),
    alias = 'dim_deal_pipeline_stage',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['STAGE_ID','SOURCE_SCHEMA']
) }}

SELECT
    STAGE_ID,
    LABEL, 
    PIPELINE_ID,
    PROBABILITY,
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_DEAL_PIPELINE_STAGE') }} 

{% if company == 'wagway'%} 

UNION ALL 

SELECT
    STAGE_ID,
    LABEL, 
    PIPELINE_ID,
    PROBABILITY,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE') }} 
{% endif %}




{% endif %}