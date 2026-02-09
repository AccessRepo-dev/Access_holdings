{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "netsuite") == "netsuite") }}

{{
    config(
        database=get_target_database(company),
        materialized="table",
        alias="rpt_monthly_financial_kpis",
    )
}}


with

    agg as (
        select

            null as state_key,--md5(coalesce(mad.state_code, '')) as state_key,
            period_start_date,
            dim_department_id,
            DIM_SUBSIDIARY_ID,
            dim_class_id,
            sum(case when a.metric_l1 = 'Revenue' then amount else 0 end) as rev,
            sum(case when a.metric_l1 = 'COGS' then amount else 0 end) as cogs,
            sum(
                case when a.metric_l1 = 'Corporate Expenses' then amount else 0 end
            ) as ce,
            sum(
                case
                    when a.metric_l1 = 'Field Corporate Expenses' then amount else 0
                end
            ) as fce,
            sum(
                case when a.metric_l1 = 'Operating Expenses' then amount else 0 end
            ) as oe,
            sum(
                case
                    when a.metric_l1 = 'Other (Income) / Expense' then amount else 0
                end
            ) as other
        from {{ ref("netsuite_fact_transaction") }} f
        left join
            {{ ref("netsuite_dim_coa") }} a
            on f.dim_chart_of_account_id = a.dim_chart_of_account_id
        group by all
    )

select
    period_start_date,
    dim_department_id,
    DIM_SUBSIDIARY_ID,
    dim_class_id,
    state_key,
    -1 * rev as revenue,
    -1 * (rev + cogs) as gross_profit,
    -1 * (rev + cogs + fce + ce + oe + other) as ebitda
from agg
