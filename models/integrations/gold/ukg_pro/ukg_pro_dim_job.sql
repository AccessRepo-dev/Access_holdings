{% set company = var('company', 'playfly') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') | lower == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_job',
    incremental_strategy = 'merge',
    unique_key = 'DIM_JOB_ID'
) }}

with source as (
    select

        ID AS DIM_JOB_ID,
        JOB_FAMILY_CODE AS JOB_CATEGORY,
      
    from {{ref('ukg_pro_job')}}
    WHERE _FIVETRAN_DELETED = False

)
select *
from source