{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'adp_workforce_now') | lower == 'adp_workforce_now') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_employment',
    incremental_strategy = 'merge',
    unique_key = 'EMPLOYEE_ID'
) }}

with source as (
    select
        HASH(CONCAT(ID,ASSOCIATE_OID)) AS DIM_EMPLOYEE_COMPANY_ID,
        ID as EMPLOYEE_ID,
        null AS DIM_COMPANY_ID,
        ORIGINAL_HIRE_DATE,
        null as HIRE_SOURCE,
        status_value as EMPLOYEE_STATUS_CODE,
        null as EMPLOYEE_TYPE_CODE,
        null as JOB_CHANGE_REASON_CODE,
        null as FULL_TIME_OR_PART_TIME_CODE,
        TERMINATION_DATE as DATE_OF_TERMINATION,
        null as TERMINATION_REASON_DESCRIPTION,
        null AS DIM_LOCATION_ID,
        null AS DIM_JOB_ID,
        null as SCHEDULED_ANNUAL_HRS,
        null as SCHEDULED_WORK_HRS,
        null AS SUPERVISOR_COMPANY_ID,
        null as SUPERVISOR_ID,          
        null as TERM_REASON,
        null as TERM_TYPE,
        null as WEEKLY_HOURS,
        null AS DIM_ORGANIZATION_LEVEL_1_ID,
        null as DATE_TIME_CHANGED,
        null as LAST_HIRE_DATE
    from {{ref('adp_workforce_now_worker')}}

)
select *
from source