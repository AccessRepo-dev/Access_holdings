{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = '_FIVETRAN_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ACCOUNTSUBSIDIARYMAP') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select 
        TRY_CAST(ACCOUNT AS INT) AS ACCOUNT,
        TRY_CAST(SUBSIDIARY AS INT) AS SUBSIDIARY,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select 
    *
from cleaned