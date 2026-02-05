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
    report as (

        select worker_id, max(report_to_worker_id) as report_to_worker_id
        from {{ ref("adp_workforce_now_worker_report_to") }}
        group by worker_id

    ),
    worker_company as (
        select a.worker_id, max(a.id) as company_id
        from {{ ref("adp_workforce_now_worker_home_organizational_unit") }} a
        join
            {{ ref("adp_workforce_now_organizational_unit") }} b
            on a.id = b.id
            and lower(b.type_short_name) = 'business unit'
        group by worker_id

    ),
    worker_department as (
        select a.worker_id, max(a.id) as department_id
        from {{ ref("adp_workforce_now_worker_home_organizational_unit") }} a
        join
            {{ ref("adp_workforce_now_organizational_unit") }} b
            on a.id = b.id
            and lower(type_short_name) = 'department'
        group by worker_id

    ),
    classifications as (
        select
            wc.worker_id,
            c.name_short_name as classification_type,
            c.id as classification_id,
            coalesce(
                c.classification_short_name, c.classification_long_name
            ) as classification_value
        from {{ ref('adp_workforce_now_worker_classification') }} wc
        join {{ ref('adp_workforce_now_classification') }} c on wc.id = c.id
    ),
    worker_classification as (
        select
            worker_id,
            -- MAX(CASE WHEN classification_type = 'Job Class' THEN classification_id
            -- END) AS job_class,
            -- MAX(CASE WHEN classification_type = 'EEOC' THEN classification_id END)
            -- AS eeoc,
            -- MAX(CASE WHEN classification_type = 'NAICS' THEN classification_id END)
            -- AS naics,
            coalesce(
                max(
                    case
                        when classification_type = 'Job Class' then classification_id
                    end
                ),
                max(case when classification_type = 'EEOC' then classification_id end),
                max(case when classification_type = 'NAICS' then classification_id end)
            ) as selected_classification
        from classifications
        group by worker_id
    ),
    source as (
        select
            hash(concat(w.id, '-', associate_oid)) as dim_employee_id,
            w.associate_oid as employee_id,
            null as hire_source,
            w.status_value as employee_status,
            coalesce(
                wah.worker_type_short_name, wah.worker_type_short_name
            ) as employee_type,
            cast(w.original_hire_date as date) as original_hire_date,
            cast(w.original_hire_date as date) as hire_date,
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
            md5(coalesce(wc.company_id, '')) as dim_company_id,
            md5(
                coalesce(home_work_location_address_city_name, '')
                || coalesce(home_work_location_address_country_code, '')
            ) as dim_location_id,
            md5(coalesce(job_title, job_short_name, job_long_name)) as dim_job_id,
            null as dim_organization_level_id,
            null as dim_parent_class_id,
            null as dim_class_id,
            md5(coalesce(wd.department_id, '')) as dim_department_id,
            md5(coalesce(wcl.selected_classification, '')) as dim_job_group_id,
            null as supervisor_company_id,
            rpt.report_to_worker_id as manager_id,
            assignment_status_reason as employee_status_reason_code,
            coalesce(job_function_short_name, job_function_long_name) as job_function,
            cast(null as int) as scheduled_annual_hours,
            cast(null as int) as scheduled_work_hours,
            cast(null as int) as weekly_hours,
            cast(null as timestamp_ntz) as date_time_changed,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("adp_workforce_now_worker") }} w
        left join report rpt on rpt.worker_id = w.id
        left join worker_company wc on wc.worker_id = w.id
        left join worker_department wd on wd.worker_id = w.id
        left join worker_classification wcl  on wcl.worker_id = w.id
        left join
            {{ ref("adp_workforce_now_work_assignment_history") }} wah
            on wah.worker_id = w.id
            and wah._fivetran_active = true
            and wah.primary_indicator = true

    )
select *
from source
