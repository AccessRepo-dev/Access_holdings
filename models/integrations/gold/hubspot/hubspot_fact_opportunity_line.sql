{% set company = var('company') %}
{{ config(enabled = var('sourcesystem', 'none') | lower in ['hubspot', 'hubspot_pawville']) and
 (var('company', 'none') | lower in ['wagway', 'playfly','amh']) }}
{{ config(
    database = get_target_database(company),
    alias = 'fact_opportunity_line',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

SELECT
    *,

FROM {{ get_silver_source(company , 'HUBSPOT_LINE_ITEM') }} 
{% if company == 'wagway'%} 

UNION ALL 

SELECT
    *
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_LINE_ITEM') }} u
{% endif %}