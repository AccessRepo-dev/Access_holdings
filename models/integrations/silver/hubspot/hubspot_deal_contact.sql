{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~'_DEAL_CONTACT',
    incremental_strategy = 'merge',
    unique_key = 'DEAL_ID,CONTACT_ID'
) }}


SELECT
    CAST(DEAL_ID AS BIGINT) AS DEAL_ID, 
    CAST(CONTACT_ID AS BIGINT) AS CONTACT_ID,
    _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from {{ get_raw_source(company, sourcesystem, 'DEAL_CONTACT') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    {% endif %}
