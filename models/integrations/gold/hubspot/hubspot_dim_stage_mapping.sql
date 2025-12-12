{% set company = var("company", "wagway") %}
{{ config(enabled = var('sourcesystem', 'hubspot') in ["hubspot", "hubspot_pawville"] and var('company','wagway') == 'wagway') }}


{{ config(
    database = get_target_database(company),
    alias = 'dim_stage_mapping',
    materialized = 'incremental',
    incremental_strategy = 'merge',
) }}

{% set derived_metrics = var('derived_metrics') %}

SELECT 
    STAGE_NAME, 
    MAPPED_STAGE_NAME, 
    CAST(sort_order as INT) as STAGE_ORDER,

    {% if company == "wagway" %}
        'HUBSPOT_PUPS' as SOURCE_SCHEMA,

    {%else%}

        CONCAT('HUBSPOT_','{{company | upper}}') as SOURCE_SCHEMA,

    {% endif %}

    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
FROM {{ get_silver_source(company, company| upper ~ '_OPPORTUNITY_STAGE_MAPPING') }}