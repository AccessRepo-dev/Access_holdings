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
    from {{ get_raw_source(company, sourcesystem, 'JOB') }}
    
),

cleaned as (
    select 
        CAST(ID AS VARCHAR) AS ID,
        TRIM(TITLE) as TITLE,
        TRIM(JOB_FAMILY_CODE) AS JOB_FAMILY_CODE,
        CURRENT_TIMESTAMP() AS SILVER_LOAD_DATE,
        _FIVETRAN_DELETED    
    from source_data
)

select 
    *
from cleaned
