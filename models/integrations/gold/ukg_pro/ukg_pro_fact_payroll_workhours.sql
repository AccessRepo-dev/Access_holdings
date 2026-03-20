{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly","spotless"],
        database=get_target_database(company),
        alias="fact_payroll_workhours",
        incremental_strategy="merge",
    )
}}

with
    source as (
        select
            annual_salary,
            currency_code,
            hash(concat(p.employee_id, p.company_id)) as dim_employee_id,
            p.employee_id,
            total_tax_amount,
            net_amount,
            bonus_total_hours,
            
            hourly_pay_rate,
            total_deduction_amount,
            total_earnings_amount,
            {% if company == 'spotless' %}
                
                CASE
                    WHEN e.full_time_or_part_time_code = 'P' and p.total_hours > 0 THEN p.total_hours
                    WHEN e.full_time_or_part_time_code = 'P' and p.total_hours < 0 THEN 0
                    ELSE e.SCHEDULED_WORK_HRS
                END AS total_hours,

                total_hours as total_hours_worked,
            {% else %}
                total_hours,
                total_hours_worked ,
            {% endif %}
            
            cast(null as int) as unpaid_absence_hours,
            cast(null as int) as paid_absence_hours,
            pay_date
        from {{ ref("ukg_pro_pay_register") }} p
        {%if company == 'spotless'%}
            left join {{ref("ukg_pro_employment")}} e on e.employee_id = p.employee_id and e.company_id = p.company_id
            where p._fivetran_deleted = false and e._fivetran_deleted = false and total_earnings_amount <> 0 and total_hours <> 0
        {%else%}
            where p._fivetran_deleted = false 
        {%endif%}
       
        
    )
,
ot as (
select 
*,
{%if company == 'spotless'%}
    CASE
        WHEN total_hours_worked > total_hours then total_hours_worked - total_hours
        ELSE 0
    END AS bonus_total_ot_hours
{%else%}
    0 as bonus_total_ot_hours
{%endif%}
from source
)
select 
* EXCLUDE(total_hours_worked), 
total_hours_worked - bonus_total_ot_hours AS total_hours_worked
from ot
