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
        alias="dim_hr_employee",
        incremental_strategy="merge",
        unique_key="EMPLOYEE_ID",
    )
}}

with
    source as (
        select
            hash(concat(w.id, associate_oid)) as dim_employee_id,
            w.id as employee_id,
            null as hire_source,
            w.status_value as employee_status,
            coalesce(
                wah.worker_type_short_name, wah.worker_type_short_name
            ) as employee_type,
            w.original_hire_date,
            null as last_hire_date,
            w.termination_date as termination_date,
            coalesce(
                wah.assignment_status_reason_short_name,
                wah.assignment_status_reason_long_name
            ) as termination_reason,
            case
                when wah.voluntary_indicator = true
                then 'Voluntary'
                when wah.voluntary_indicator = false
                then 'Involuntary'
                else 'Termination'
            end as termination_type,
            null as dim_company_id,
            null as dim_location_id,
            md5(coalesce(job_title, job_short_name, job_long_name)) as dim_job_id,
            null as dim_organization_level_id,
            null as supervisor_company_id,
            rpt.report_to_worker_id as manager_id,
            assignment_status_reason as employee_status_reason_code,
            coalesce(job_function_short_name, job_function_long_name) as job_function,
            null as scheduled_annual_hours,
            null as scheduled_work_hours,
            null as weekly_hours,
            null as date_time_changed,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("adp_workforce_now_worker") }} w
        left join {{ ref('adp_workforce_worker_report_to') }} rpt on rpt.worker_id = w.worker_id
        left join
            {{ ref("adp_workforce_now_work_assignment_history") }} wah
            on wah.worker_id = w.id
            and wah._fivetran_active = true
            and wah.primary_indicator = true

    )
select *
from source
