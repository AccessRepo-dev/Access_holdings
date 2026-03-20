{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        alias="fact_employee_salary_details",
        incremental_strategy="merge",
    )
}}


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
FROM {{ ref("adp_workforce_now_fact_payroll_workhours") }}
UNPIVOT (
    amount FOR earning_type IN (
        total_tax_amount ,
        net_amount ,
        total_deduction_amount 
    )
)

