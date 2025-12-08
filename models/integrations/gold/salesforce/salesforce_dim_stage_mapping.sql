{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_stage_mapping',
    materialized = 'incremental',
    incremental_strategy = 'merge',
) }}

{% set derived_metrics = var('derived_metrics') %}

SELECT 
    old_stage, 
    new_stage, 
    CAST(probability as NUMBER(35,17)) as probability,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
FROM {{ get_silver_source(company, company ~ '_OPPORTUNITY_STAGE_MAPPING') }}