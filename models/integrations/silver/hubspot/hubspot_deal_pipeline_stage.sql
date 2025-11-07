{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~ '_DEAL_PIPELINE_STAGE',
    incremental_strategy = 'merge',
    unique_key = 'STAGE_ID'
) }}

select
    CAST(STAGE_ID AS varchar) AS STAGE_ID,
    TRIM(LABEL) AS LABEL,
    CAST(PIPELINE_ID AS varchar) AS PIPELINE_ID,
    CAST(PROBABILITY AS FLOAT) AS PROBABILITY, 
    _FIVETRAN_SYNCED
from {{ get_raw_source(company, sourcesystem, 'DEAL_PIPELINE_STAGE') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
