{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        alias="fact_payroll_workhours",
        incremental_strategy="merge",
    )
}}

WITH latest_comp AS (
    SELECT
        EMPLOYEE_ACCOUNT_ID,
        AMOUNT,
        HOURLY_PAY,
        AMOUNT_PERIOD,
        CURRENCY,
        TIME_PERIOD,
        TIME,
        EFFECTIVE_FROM ,
        LEAD(EFFECTIVE_FROM) OVER (
            PARTITION BY EMPLOYEE_ACCOUNT_ID
            ORDER BY EFFECTIVE_FROM
        ) AS effective_till
        
    FROM   {{ ref("ukg_ready_compensation_history") }}
     WHERE EFFECTIVE_FROM <> '1900-12-31'
)
SELECT
    cast(null as float) as annual_salary,
    lc.CURRENCY as currency_code,
    e.dim_employee_id,
    e.employee_id,

    cast(null as float) as  total_tax_amount,
    cast(null as float) as  net_amount,
    cast(null as float) as  bonus_total_hours,
    cast(null as float) as  bonus_total_ot_hours,
    lc.HOURLY_PAY       AS HOURLY_PAY_RATE,
    cast(null as float) as  total_deduction_amount,
    CASE 
        WHEN UPPER(TIME_PERIOD) = 'YEAR' THEN TIME/936000000.0 
         ELSE TIME/18000000.0 
    END AS  TOTAL_HOURS,
    CASE 
        WHEN te.time_entries_time_off_id IS not NULL 
        THEN 0
        ELSE  te.TIME_ENTRIES_CALC_TOTAL / 3600000.0 
    END  AS total_hours_worked, 
    te.TIME_ENTRIES_DATE AS pay_date,
    CASE
        WHEN te.time_entries_time_off_id IS not NULL 
        THEN  TIME_ENTRIES_CALC_TOTAL/ 3600000
        ELSE 0
    END AS PAID_ABSENCE_HOURS,
    (PAID_ABSENCE_HOURS + total_hours_worked) * HOURLY_PAY_RATE AS TOTAL_EARNINGS_AMOUNT,
    cast(null as int) as unpaid_absence_hours,
    current_timestamp()::timestamp_ntz AS gold_load_date
    
FROM  {{ ref("ukg_ready_time_entries") }} te
LEFT JOIN {{ ref("ukg_ready_dim_employee") }} e
    ON te.EMPLOYEE_ACCOUNT_ID = e.dim_employee_id
LEFT JOIN latest_comp lc
    ON te.EMPLOYEE_ACCOUNT_ID = lc.EMPLOYEE_ACCOUNT_ID
    AND te.time_entries_date >= EFFECTIVE_FROM and te.time_entries_date < COALESCE(EFFECTIVE_TILL,  '2050-01-01')





