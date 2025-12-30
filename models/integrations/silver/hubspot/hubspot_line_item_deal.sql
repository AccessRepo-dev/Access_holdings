{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot','hubspot_pawville'] and var('company') | lower in ['wagway', 'playfly','amh'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_LINE_ITEM_DEAL',
    incremental_strategy = 'merge',
    unique_key = 'LINE_ITEM_ID'
) }}


    SELECT
        CATEGORY,
        TYPE_ID,
        DEAL_ID,
        LINE_ITEM_ID,
        _FIVETRAN_SYNCED
    FROM
    {{ get_raw_source(company, sourcesystem, 'LINE_ITEM_DEAL') }}

