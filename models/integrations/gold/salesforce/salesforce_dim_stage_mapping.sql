{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce' and var('company','zeus') == 'zeus') }}

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
    CAST(sort_order as INT)+1 as STAGE_ORDER,
    CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
FROM {{ get_silver_source(company, company ~ '_OPPORTUNITY_STAGE_MAPPING') }}

union 

SELECT 
    'Lead' as STAGE_NAME, 
    'Lead' as MAPPED_STAGE_NAME, 
    1 as STAGE_ORDER,
    CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
FROM {{ get_silver_source(company, company ~ '_OPPORTUNITY_STAGE_MAPPING') }}