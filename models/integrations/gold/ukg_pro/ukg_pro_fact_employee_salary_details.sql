{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly","spotless"],
        database=get_target_database(company),
        alias="fact_employee_salary_details",
        incremental_strategy="merge",
    )
}}

{%if company == 'playfly'%}
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

{%else%}
     SELECT
    dim_employee_id,
    employee_id,
    CASE LOWER(earning_type)
    WHEN 'total_tax_amount' THEN 1
    WHEN 'total_deduction_amount' THEN 2
    WHEN 'net_amount' THEN 3 
END AS dim_earning_id,
    NULL AS dim_company_id,
    NULL AS location_id,
    NULL AS job_id,
    NULL AS pay_group,
    amount AS base_amount,
    total_hours_worked AS current_hours,
    hourly_pay_rate AS ctc_hourly_pay_rate,
    hourly_pay_rate AS base_hourly_pay_rate,
    pay_date,
    NULL AS period_pay_rate,
    NULL AS tax_category,
    amount AS current_amount,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS gold_load_date
FROM {{ ref("ukg_pro_fact_payroll_workhours") }}
UNPIVOT (
    amount FOR earning_type IN (
        total_tax_amount ,
        net_amount ,
        total_deduction_amount 
    )
)
{%endif%}
