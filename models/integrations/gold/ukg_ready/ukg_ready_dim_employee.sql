{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
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
            hash(dim_company_id, employee_id) as dim_employee_id,
            hash(employee_id) as employee_id,
            null as hire_source,
            null as employee_status,
            'Full Time' as employee_type,
            cast(hired_date as date) as original_hire_date,
            cast(hired_date as date) as hire_date,
            cast(terminated_date as date) as termination_date,
            null as termination_reason,
            null as termination_type,
            dim_company_id as dim_company_id,
            null as dim_location_id,
            null as dim_job_id,
            null as dim_parent_class_id,
            null as dim_class_id,
            null as dim_department_id,
            null as dim_location_ns_id,
            null as supervisor_company_id,
            null as manager_id,
            null as employee_status_reason_code,
            null as job_function,
            cast(null as int) as scheduled_annual_hours,
            cast(null as int) as scheduled_work_hours,
            cast(null as int) as weekly_hours,
            cast(null as timestamp_ntz) as date_time_changed,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_ready_employees") }} e
        left join {{ ref("ukg_ready_dim_company") }} c on c.company_name = e.ein_name

    )
select *
from source