{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}
{{ config(
    enabled = false,
    database = get_target_database(company),
    alias = 'dim_deal_pipeline',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['DIM_DEAL_PIPELINE_ID','SOURCE_SCHEMA']
) }}

SELECT
    PIPELINE_ID AS DIM_DEAL_PIPELINE_ID,
    LABEL, 
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_DEAL_PIPELINE') }} 

{% if company == 'wagway'%} 

UNION ALL 

SELECT
    PIPELINE_ID AS DIM_DEAL_PIPELINE_ID,
    LABEL,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_DEAL_PIPELINE') }} 
{% endif %}