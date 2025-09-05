{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}
{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'LOCATION_ID'
) }}

with source as (
    select
        ID AS LOCATION_ID,
        NAME AS LOCATION_NAME,
        FULLNAME AS LOCATION_FULL_NAME,
        LOCATIONTYPE AS LOCATION_TYPE,
        PARENT AS PARENT,
        SUBSIDIARY AS SUBSIDIARY_ID,
        LATITUDE AS LATITUDE,
        LONGITUDE AS LONGITUDE,
        ISINACTIVE AS IS_INACTIVE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'netsuite_location') }}
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
