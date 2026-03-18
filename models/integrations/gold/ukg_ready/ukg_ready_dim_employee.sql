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
        select distinct
            e.ID as dim_employee_id, 
            e.primary_account_id as employee_id,
            null as hire_source,
            e.status as employee_status,
            CASE WHEN ch.amount_period = 'HOUR' then 'Part Time' ELSE 'Full Time' END  as employee_type,
            cast(hired_date as date) as original_hire_date,
            cast(hired_date as date) as hire_date,
            cast(terminated_date as date) as termination_date,
            null as termination_reason,
            null as termination_type,
            dim_company_id,
            store.PARENT_ID as dim_location_id,
            d.COST_CENTER_JOB_ID as dim_job_id,
            null as dim_class_id,
            job.PARENT_ID as dim_department_id,
            null as dim_job_group_id,
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
        left join ( SELECT DISTINCT EMPLOYEE_ACCOUNT_ID, AMOUNT_PERIOD,
                   ROW_NUMBER() OVER (PARTITION BY EMPLOYEE_ACCOUNT_ID ORDER BY effective_from DESC) as  ROW_NUMBER
                    FROM {{ ref("ukg_ready_compensation_history") }} WHERE EFFECTIVE_FROM <> '1900-12-31') ch
                     on ch.employee_account_id = e.ID  and ROW_NUMBER = 1
        left join  {{ ref("ukg_ready_employee_details") }}  d on e.ID = d.ID
        left join {{ref("ukg_ready_cost_center_org")}} job on d.COST_CENTER_JOB_ID = job.ID
        left join {{ref("ukg_ready_cost_center_store")}} store on d.COST_CENTER_STORE_ID = store.ID
        where lower(e.employee_id) not like '%test%' and lower(e.employee_id) not like 'v%' 
        
    )
select *
from source s

