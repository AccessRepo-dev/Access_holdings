{% set company = var("company", "amh") %}
{% set sourcesystem = var("sourcesystem", "paycom") %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
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
            employee_code as dim_employee_id,
            employee_code as employee_id,
            null as hire_source,
            case
                when employee_status = 'T'
                then 'Terminated'
                when employee_status = 'A'
                then 'Active'
                when employee_status = 'I'
                then 'Inactive'
                when employee_status = 'R'
                then 'Retired'
                else 'Unknown'
            end as employee_status,
            case
                when DOL_STATUS = 'Full Time'
                then 'Full Time'
                else 'Part time'
            end as employee_type,
            cast(hire_date as date) as original_hire_date,
            cast(hire_date as date) as hire_date,
            cast(termination_date as date) as termination_date,
            termination_reason as termination_reason,
            case
            when termination_date is null then ''
            when ttm.mapped_termination_type is null then 'Unknown' 
            else ttm.mapped_termination_type end as termination_type,
            null as dim_company_id,
            hash(location) as dim_location_id,
            hash(position_title) as dim_job_id,
            null as dim_class_id,
            hash(department_description) as dim_department_id,
            hash(position_family) as dim_job_group_id,
            -- md5(coalesce(organization_level_1_id, '') || coalesce(1, '') ) as
            -- dim_organization_level_id,
            -- md5(coalesce(organization_level_2_id, '') || coalesce(2, '') ) as
            -- dim_class_id,
            -- md5(coalesce(organization_level_4_id, '') || coalesce(4, '') ) as
            -- dim_location_ns_id,
            null as supervisor_company_id,
            coalesce(supervisor_primary_code, supervisor_secondary_code, supervisor_tertiary_code, supervisor_quaternary_code) as manager_id,
            null as employee_status_reason_code,
            null as job_function,
            custom_standard_hours as scheduled_annual_hours,
            custom_standard_hours as scheduled_work_hours,
            null as weekly_hours,
            most_recent_check_date as date_time_changed,
            -- employee_type_code,
            -- term_reason,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("paycom_employees") }} e
        left join {{ ref('amh_termination_type_mapping') }} ttm ON lower(ttm.termination_type) = lower(e.termination_type)

    )
select *
from source