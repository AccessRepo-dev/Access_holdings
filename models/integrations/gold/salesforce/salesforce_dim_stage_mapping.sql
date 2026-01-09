{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
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
    md5(
        coalesce(stage_name, '')
        || concat('SALESFORCE_', '{{company | upper}}')
    ) as STAGE_KEY,
    CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
FROM {{ get_silver_source(company, company ~ '_OPPORTUNITY_STAGE_MAPPING') }}