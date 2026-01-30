{% set company = var('company', 'playfly') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') | lower == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_organization',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ORGANIZATION_LEVEL_ID'
) }}

with source as (
    select
        ID AS DIM_ORGANIZATION_LEVEL_ID,
        LEVEL, 
        LEVEL_DESCRIPTION,
        DESCRIPTION,
        
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
      
    from {{ref('ukg_pro_organization_level')}}
    WHERE IS_ACTIVE = True

)
select *
from source