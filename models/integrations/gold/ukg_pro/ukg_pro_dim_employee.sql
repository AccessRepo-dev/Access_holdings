{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly","spotless"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_hr_employee",
        incremental_strategy="merge",
        unique_key="dim_employee_id",
    )
}}

with
    source as (
        select
            hash(concat(employee_id, company_id)) as dim_employee_id,
            employee_id,
            hire_source,
            case
                when employee_status_code = 'T'
                then 'Terminated'
                when employee_status_code = 'A'
                then 'Active'
                when employee_status_code = 'L'
                then 'Leave'
                else 'Unknown'
            end as employee_status,
            case
                when full_time_or_part_time_code = 'P'
                then 'Part Time'
                when full_time_or_part_time_code = 'F'
                then 'Full Time'
                else 'Unknown'
            end as employee_type,
            cast(original_hire_date as date) as original_hire_date,
            cast(last_hire_date as date) as hire_date,
            cast(date_of_termination as date) as termination_date,
            termination_reason_description as termination_reason,
            case
                when date_of_termination is null 
                then ''
                when term_type = 'I'
                then 'Involuntary'
                when term_type = 'V'
                then 'Voluntary'
                else 'Unknown'
            end as termination_type,
            company_id as dim_company_id,
            primary_work_location_id as dim_location_id,
            primary_job_id as dim_job_id,
            organization_level_1_id as dim_class_id,
            organization_level_3_id as dim_department_id,
            hash(coalesce(j.job_family_code, '')) as dim_job_group_id,
            md5(coalesce(supervisor_co_id, '')) as supervisor_company_id,
            supervisor_id as manager_id,
            job_change_reason_code as employee_status_reason_code,
            null as job_function,
            scheduled_annual_hrs as scheduled_annual_hours,
            scheduled_work_hrs as scheduled_work_hours,
            weekly_hours,
            date_time_changed,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_employment") }} e
        left join {{ ref("ukg_pro_job") }} j on j.id = e.primary_job_id
        where e._FIVETRAN_DELETED = FALSE

    )
select *
from source
