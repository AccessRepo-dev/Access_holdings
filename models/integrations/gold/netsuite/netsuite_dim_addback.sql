{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') | lower == 'netsuite') }}
{{ config(enabled = var('company', 'none') | lower == 'wagway') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_addback',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ADDBACK_ID'
) }}

with source as (

    select
        ID as DIM_ADDBACK_ID,
        NAME,
        ISINACTIVE AS IS_INACTIVE,
        LASTMODIFIED as LAST_MODIFIED_DATE
    from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_CUSTOMRECORD_CSEG1') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)

    {% if is_incremental() %}
        and LASTMODIFIED > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source
