{% set company = var('company', 'playfly') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') | lower == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_company_hr',
    incremental_strategy = 'merge',
    unique_key = 'DIM_JOB_ID'
) }}

with source as (
    select

        ID AS DIM_COMPANY_ID,
        COMPANY_CODE,
        COMPANY_NAME
      
    from {{ref('ukg_pro_company')}}

)
select *
from source