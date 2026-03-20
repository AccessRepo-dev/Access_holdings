{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower)
        in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        alias="fact_payroll_workhours",
        incremental_strategy="merge",
    )
}}

with
    active_FT as (
        SELECT 
            e.dim_employee_id as associate_oid,
            'Unknown' as worker_id,
            'Unknown' as time_card_id,
            d.entry_date,
            'Unknown' as pay_code,
            'PT8H' as time_duration,
            'Unknown' as bucket,
            8 as hours,
            0 as minutes,
            null as seconds

        FROM {{ ref("adp_workforce_now_dim_employee") }} e
        LEFT JOIN (
            SELECT DISTINCT associate_oid 
            FROM {{ ref("adp_workforce_now_worker_time_card") }} t
        ) t ON e.dim_employee_id = t.associate_oid
        CROSS JOIN (
            SELECT DATEADD(day, seq4(), '2020-01-01'::date) AS entry_date
            FROM TABLE(GENERATOR(ROWCOUNT => 50000))
        ) d
        WHERE 
            t.associate_oid is null
            AND e.employee_status = 'Active'
            AND e.employee_type = 'Full Time'
            AND d.entry_date BETWEEN e.hire_date AND CURRENT_DATE()
            AND DAYOFWEEK(d.entry_date) NOT IN (0, 6) 
        

    ),
    hours_cte as (
        select
            associate_oid,
            worker_id,
            time_card_id,
            entry_date,
            wtct.pay_code,
            time_duration,
            bucket,
            try_to_number(
                regexp_substr(time_duration, 'PT([0-9]+)H', 1, 1, 'e', 1)
            ) as hours,
            try_to_number(
                regexp_substr(time_duration, '([0-9]+)M', 1, 1, 'e', 1)
            ) as minutes,
            try_to_number(
                regexp_substr(time_duration, '([0-9]+)S', 1, 1, 'e', 1)
            ) as seconds
        from {{ ref("adp_workforce_now_worker_time_card") }} wtc
        left join
            {{ ref("adp_workforce_now_worker_time_card_daily_total") }} wtct
            on wtc.id = wtct.time_card_id
        left join
            {{ ref("adp_workforce_now_dim_pay_code_mapping") }} pm
            on pm.pay_code = wtct.pay_code
    
     union 
        select
            associate_oid,
            worker_id,
            time_card_id,
            entry_date,
            pay_code,
            time_duration,
            bucket,
            hours,
            minutes,
            seconds
        from active_FT

    ),

    hours as (
        select
            associate_oid,
            worker_id,
            entry_date,
            case
                when bucket = 'Regular'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as total_hours_worked_cte,
            case
                when bucket = 'Overtime'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as bonus_total_ot_hours_cte,
            case
                when bucket = 'Paid Absence'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as paid_absence_hours,
            case
                when bucket = 'Unpaid Absence'
                then
                    sum(
                        coalesce(hours, 0)
                        + coalesce(minutes, 0) / 60
                        + coalesce(seconds, 0) / 3600
                    )
                else 0
            end as unpaid_absence_hours
        from hours_cte
        group by 1, 2, 3, bucket
    ),
    pay_rate as (

        select

            effective_date as effective_from,
            case
                when
                    row_number() over (
                        partition by worker_id order by effective_date desc
                    )
                    = 1
                then null
                else
                    lag(effective_date) over (
                        partition by worker_id order by effective_date desc
                    )
            end as effective_to,
            p.worker_id,
            w.associate_oid,
            annual_rate_amount_amount_value,
            hourly_rate_amount_amount_value
        from {{ ref("adp_workforce_now_worker_base_remuneration") }} p
        left join {{ ref('adp_workforce_now_worker') }} w ON w.id = p.worker_id 

    ),
    source as (
        select
            annual_rate_amount_amount_value as annual_salary,
            null as currency_code,
            h.associate_oid as dim_employee_id,
            h.associate_oid as employee_id,
            cast(null as float) as total_tax_amount,
            
            cast(null as int) as bonus_total_hours,
            hourly_rate_amount_amount_value as hourly_pay_rate,
            8 as total_hours,
            sum(h.total_hours_worked_cte) as total_hours_worked,
            sum(h.bonus_total_ot_hours_cte) as bonus_total_ot_hours,
            sum(h.paid_absence_hours) as paid_absence_hours,
            sum(h.unpaid_absence_hours) as unpaid_absence_hours,
            cast(null as float) as total_deduction_amount,
            (total_hours_worked + bonus_total_ot_hours)* hourly_pay_rate as total_earnings_amount,
            cast(total_earnings_amount as float) as net_amount,
            h.entry_date as pay_date,
            current_timestamp()::timestamp_ntz as gold_load_date
        from hours h
        left join
            {{ ref("adp_workforce_now_dim_employee") }} e
            on e.dim_employee_id = h.associate_oid
        left join
            pay_rate p
            on p.associate_oid = h.associate_oid and h.entry_date >= p.effective_from and (h.entry_date <= p.effective_to OR p.effective_to is null)
        group by
            h.worker_id,
            h.associate_oid,
            entry_date,
            annual_rate_amount_amount_value,
            hourly_rate_amount_amount_value
    )
select *
from source
