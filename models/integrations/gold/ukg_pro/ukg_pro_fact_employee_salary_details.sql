{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        alias="fact_employee_salary_details",
        incremental_strategy="merge",
    )
}}

with
    source as (
        select
            employment_id,
            hash(concat(employee_id, company_id)) as dim_employee_id,
            employee_id,
            earning_id as dim_earning_id,
            company_id as dim_company_id,
            location_id as dim_location_id,
            job_id as dim_job_id,
            pay_group,
            base_amount,
            current_hours,
            hourly_pay_rate as ctc_hourly_pay_rate,
            pay_rate as base_hourly_pay_rate,
            pay_date,
            period_pay_rate,
            tax_category,
            current_amount,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_earning_history_base_element") }}
        where _fivetran_deleted = false
    )
select *
from source
