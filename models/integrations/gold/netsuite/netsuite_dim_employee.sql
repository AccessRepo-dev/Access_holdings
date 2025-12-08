{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_employee',
    incremental_strategy = 'merge',
    unique_key = 'DIM_EMPLOYEE_ID'
) }}

with source as (
    select
        ID as DIM_EMPLOYEE_ID,
        TITLE as TITLE,
        EMAIL as EMAIL,
        DEPARTMENT as DEPARTMENT_ID,
        CLASS as CLASS_ID,
        LOCATION as LOCATION_ID,
        SUBSIDIARY AS SUBSIDIARY_ID,
        ISINACTIVE as IS_INACTIVE,
        DATECREATED as DATE_CREATED,
        LASTMODIFIEDDATE as LAST_MODIFIED_DATE
    from {{ref('netsuite_employee')}}
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