{% set company = var("company", "spotless") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "spotless") | lower) in ["playfly","spotless"],
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key=['company_id', 'employee_id']
) }}

with source_data as (
    select * from {{ get_raw_source(company, sourcesystem, 'EMPLOYMENT') }}
    {% if is_incremental() %}
    where 
        cast(DATE_TIME_CHANGED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(DATE_TIME_CHANGED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    {% endif %}
),

cleaned as (
    select 
        TRY_CAST(EMPLOYEE_ID AS VARCHAR)                     AS EMPLOYEE_ID,
        TRY_CAST(COMPANY_ID AS VARCHAR)                      AS COMPANY_ID,
        CAST(ORIGINAL_HIRE_DATE AS TIMESTAMP_NTZ)            AS ORIGINAL_HIRE_DATE,
        {% if company == 'playfly'%}
        CAST(COALESCE(NULLIF(TRIM(HIRE_SOURCE), ''), 'Unknown') AS VARCHAR) AS HIRE_SOURCE,
        {%else%}
        Null as HIRE_SOURCE,
        {%endif%}
        CAST(TRIM(EMPLOYEE_STATUS_CODE) AS VARCHAR)          AS EMPLOYEE_STATUS_CODE,
        CAST(EMPLOYEE_TYPE_CODE AS VARCHAR)                  AS EMPLOYEE_TYPE_CODE,
        CAST(JOB_CHANGE_REASON_CODE AS VARCHAR)              AS JOB_CHANGE_REASON_CODE,
        CAST(FULL_TIME_OR_PART_TIME_CODE AS VARCHAR)         AS FULL_TIME_OR_PART_TIME_CODE,
        CAST(DATE_OF_TERMINATION AS DATE)                    AS DATE_OF_TERMINATION,
        CAST(TERMINATION_REASON_DESCRIPTION AS VARCHAR)      AS TERMINATION_REASON_DESCRIPTION,
        CAST(PRIMARY_WORK_LOCATION_ID AS VARCHAR)            AS PRIMARY_WORK_LOCATION_ID,
        CAST(PRIMARY_JOB_ID AS VARCHAR)                      AS PRIMARY_JOB_ID,
        CAST(SCHEDULED_ANNUAL_HRS AS FLOAT)                  AS SCHEDULED_ANNUAL_HRS,
        CAST(SCHEDULED_WORK_HRS AS FLOAT)                    AS SCHEDULED_WORK_HRS,
        CAST(SUPERVISOR_CO_ID AS VARCHAR)                    AS SUPERVISOR_CO_ID,
        CAST(SUPERVISOR_ID AS VARCHAR)                       AS SUPERVISOR_ID,
        CAST(TERM_REASON AS VARCHAR)                         AS TERM_REASON,
        CAST(TERM_TYPE AS VARCHAR)                           AS TERM_TYPE,
        CAST(WEEKLY_HOURS AS FLOAT)                          AS WEEKLY_HOURS,
        CAST(ORGANIZATION_LEVEL_1_ID AS VARCHAR)             AS ORGANIZATION_LEVEL_1_ID,
        CAST(ORGANIZATION_LEVEL_2_ID AS VARCHAR)             AS ORGANIZATION_LEVEL_2_ID,
        CAST(ORGANIZATION_LEVEL_3_ID AS VARCHAR)             AS ORGANIZATION_LEVEL_3_ID,
        CAST(ORGANIZATION_LEVEL_4_ID AS VARCHAR)             AS ORGANIZATION_LEVEL_4_ID,
        CAST(DATE_TIME_CHANGED AS TIMESTAMP_NTZ)             AS DATE_TIME_CHANGED,
        CAST(LAST_HIRE_DATE AS DATE)                         AS LAST_HIRE_DATE,
        CAST(_FIVETRAN_DELETED as BOOLEAN)             AS _FIVETRAN_DELETED

    from source_data
)

select 
    *
from cleaned
