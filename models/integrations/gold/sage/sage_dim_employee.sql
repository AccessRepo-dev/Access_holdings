
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_EMPLOYEE_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_EMPLOYEE_ID,
        EMPLOYEEID AS EMPLOYEE_ID,
        TITLE AS TITLE,
        PERSONALINFO_EMAIL_1 AS EMAIL,
        DEPARTMENTID AS DEPARTMENT_ID,
        LOCATIONID AS LOCATION_ID,
        MEGAENTITYID AS SUBSIDIARY,
        ENTITY AS ENTITY_ID,
        EMPTYPEKEY AS EMPLOYEE_TYPE_ID,
        STATUS AS IS_INACTIVE,
        WHENCREATED AS DATE_CREATED,
        WHENMODIFIED AS LAST_MODIFIED_DATE
  

    from {{ get_silver_source(company, 'sage_employee') }}
    
    {% if is_incremental() %}
    and WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source