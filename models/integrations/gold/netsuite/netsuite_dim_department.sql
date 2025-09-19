{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_department',
    incremental_strategy = 'merge',
    unique_key = 'DEPARTMENT_ID'
) }}

with source as (
    select
        ID AS DIM_DEPARTMENT_ID,
        NAME AS DEPARTMENT_NAME,
        PARENT AS PARENT,
        ISINACTIVE AS IS_INACTIVE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'DEPARTMENT') }}
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