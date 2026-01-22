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
    from {{ get_raw_source(company, sourcesystem, 'ORGANIZATION_LEVEL') }}
    
),

cleaned as (
    select 
        CAST(ID AS VARCHAR) AS ID,
        CAST(LEVEL AS INT) AS LEVEL, 
        TRIM(LEVEL_DESCRIPTION) AS LEVEL_DESCRIPTION ,
        CAST(IS_ACTIVE AS BOOLEAN) AS IS_ACTIVE,
        CURRENT_TIMESTAMP() AS SILVER_LOAD_DATE,
        _FIVETRAN_DELETED
    from source_data
)

select 
    *
from cleaned
