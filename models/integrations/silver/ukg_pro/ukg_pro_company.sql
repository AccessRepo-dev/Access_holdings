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
    from {{ get_raw_source(company, sourcesystem, 'COMPANY') }}
    
),

cleaned as (
    select 
        CAST(ID AS VARCHAR)   AS ID,
        TRIM(CODE)  AS COMPANY_CODE,
        TRIM(NAME) AS COMPANY_NAME

    from source_data
)

select 
    *
from cleaned
