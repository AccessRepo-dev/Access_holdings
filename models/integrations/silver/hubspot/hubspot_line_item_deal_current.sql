{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_LINE_ITEM_DEAL',
    incremental_strategy = 'merge',
    unique_key = 'LINE_ITEM_ID'
) }}


    SELECT {{ hs_canonical_line_item_deal(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    FROM {{ get_raw_source(company, sourcesystem, 'LINE_ITEM_DEAL') }}

