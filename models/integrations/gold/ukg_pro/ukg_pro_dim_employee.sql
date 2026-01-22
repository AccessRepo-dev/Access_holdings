{% set company = var('company', 'playfly') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') | lower == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_employment',
    incremental_strategy = 'merge',
    unique_key = 'EMPLOYEE_ID'
) }}

with source as (
    select
        EMPLOYEE_ID,
        COMPANY_ID              AS DIM_COMPANY_ID,
        ORIGINAL_HIRE_DATE,
        HIRE_SOURCE,
        EMPLOYEE_STATUS_CODE,
        EMPLOYEE_TYPE_CODE,
        JOB_CHANGE_REASON_CODE,
        FULL_TIME_OR_PART_TIME_CODE,
        DATE_OF_TERMINATION,
        TERMINATION_REASON_DESCRIPTION,
        PRIMARY_WORK_LOCATION_ID AS DIM_LOCATION_ID,
        PRIMARY_JOB_ID           AS DIM_JOB_ID,
        SCHEDULED_ANNUAL_HRS,
        SCHEDULED_WORK_HRS,
        SUPERVISOR_CO_ID         AS SUPERVISOR_COMPANY_ID,
        SUPERVISOR_ID,          
        TERM_REASON,
        TERM_TYPE,
        WEEKLY_HOURS,
        ORGANIZATION_LEVEL_1_ID  AS DIM_ORGANIZATION_LEVEL_1_ID,
        DATE_TIME_CHANGED,
        LAST_HIRE_DATE

    from {{ref('ukg_pro_employment')}}

)
select *
from source