{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') | lower == 'netsuite') }}
{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_location',
    incremental_strategy = 'merge',
    unique_key = 'DIM_LOCATION_ID'
) }}

with source as (
    select
        ID AS DIM_LOCATION_ID,
        NAME AS LOCATION_NAME,
        PARENT AS PARENT,
        PARENT_NAME,
        LOCATIONTYPE AS SITE_STATUS,
        SUBSIDIARY AS SUBSIDIARY_ID,
        ISINACTIVE AS IS_INACTIVE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ ref('netsuite_location') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
    and LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source
