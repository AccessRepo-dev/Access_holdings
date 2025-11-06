{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias =  sourcesystem ~ '_ENGAGEMENT',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

select
    CAST(ID AS INT) AS ID,
    CAST(TYPE AS VARCHAR) AS TYPE,
    _FIVETRAN_SYNCED
from {{ get_raw_source(company, sourcesystem, 'ENGAGEMENT') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
