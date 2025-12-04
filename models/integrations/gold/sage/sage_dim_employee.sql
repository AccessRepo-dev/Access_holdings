
{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_employee',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_EMPLOYEE_ID'
) }}

with source as (
    select
        RECORDNO AS DIM_EMPLOYEE_ID,
        TITLE AS TITLE,
        PERSONALINFO_EMAIL_1 AS EMAIL,
        DEPARTMENTKEY AS DEPARTMENT_ID,
        NULL AS CLASS_ID,
        LOCATIONKEY AS LOCATION_ID,
        MEGAENTITYKEY AS SUBSIDIARY_ID,
        STATUS AS IS_INACTIVE,
        WHENCREATED AS DATE_CREATED,
        WHENMODIFIED AS LAST_MODIFIED_DATE
    from {{ ref('sage_employee') }}
    
    {% if is_incremental() %}
    where WHENMODIFIED > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source