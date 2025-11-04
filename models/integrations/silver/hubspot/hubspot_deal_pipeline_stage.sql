{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'DEAL_PIPELINE_STAGE',
    incremental_strategy = 'merge',
    unique_key = 'STAGE_ID'
) }}

select
    STAGE_ID,
    LABEL,
    PIPELINE_ID
from {{ get_raw_source(company, sourcesystem, 'DEAL_PIPELINE_STAGE') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
