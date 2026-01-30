{% set company = var("company", "zeus") | lower %}
{{
    config(
        enabled=var("sourcesystem", "adp_workforce_now") | lower
        == "adp_workforce_now"
    )
}}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_employment",
        incremental_strategy="merge",
        unique_key="EMPLOYEE_ID",
    )
}}

with
    source as (
        select
            hash(concat(w.id, associate_oid)) as dim_employee_company_id,
            w.id as employee_id,
            null as dim_company_id,
            w.original_hire_date,
            null as hire_source,
            w.status_value as employee_status,
            null as employee_type,
            null as job_change_reason_code,
            coalesce(
                wah.worker_type_short_name, wah.worker_type_short_name
            ) as full_time_or_part_time,
            w.termination_date as date_of_termination,
            coalesce(
                wah.assignment_status_reason_short_name,
                wah.assignment_status_reason_long_name
            ) as termination_reason_description,
            null as dim_location_id,
            md5(coalesce(job_title, job_short_name, job_long_name)) as dim_job_id,
            coalesce(job_function_short_name, job_function_long_name) as job_function,
            null as scheduled_annual_hrs,
            null as scheduled_work_hrs,
            null as supervisor_company_id,
            null as supervisor_id,
            null as term_reason,
            case
                when wah.voluntary_indicator = true
                then 'Voluntary'
                when wah.voluntary_indicator = false
                then 'Involuntary'
                else 'Termination'
            end as termination_type,
            null as weekly_hours,
            null as dim_organization_level_1_id,
            null as date_time_changed,
            null as last_hire_date,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("adp_workforce_now_worker") }} w
        left join
            {{ ref("adp_workforce_now_work_assignment_history") }} wah
            on wah.worker_id = w.id
            and wah._fivetran_active = true
            and wah.primary_indicator = true

    )
select *
from source
