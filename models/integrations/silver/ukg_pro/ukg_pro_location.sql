{% set company = var('company', 'playfly') | lower %}
{% set sourcesystem  = var('sourcesystem', 'ukg_pro') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'LOCATION') }}
    
),

cleaned as (
    select 
        CAST(ID AS VARCHAR) AS ID,
        TRIM(CITY) AS CITY,
        TRIM(COUNTRY_CODE) AS COUNTRY_CODE,
        CAST(IS_ACTIVE AS boolean) AS IS_ACTIVE,
        TRIM(STATE) AS STATE,
        CAST(ZIP_OR_POSTAL_CODE AS INT) AS ZIP_OR_POSTAL_CODE,
        _FIVETRAN_DELETED
    from source_data
)

select 
    *
from cleaned
