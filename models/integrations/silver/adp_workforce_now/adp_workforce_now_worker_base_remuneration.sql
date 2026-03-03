{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower)
        in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "WORKER_BASE_REMUNERATION") }}
        {% if is_incremental() %}
            where
                _fivetran_synced > (
                    select
                        dateadd(day, -3, coalesce(max(_fivetran_synced), '1900-01-01'))
                    from {{ this }}
                )
        {% else %} where 1 = 1
        {% endif %}

    ),

    cleaned as (
        select

            trim(coalesce(worker_assignment_id, '')) as worker_assignment_id,
            trim(coalesce(worker_id, '')) as worker_id,
            cast(effective_date as date) as effective_date,
            trim(
                hourly_rate_amount_name_short_name
            ) as hourly_rate_amount_name_short_name,
            cast(
                hourly_rate_amount_amount_value as number
            ) as hourly_rate_amount_amount_value,
            cast(
                hourly_rate_amount_percentage_value as number
            ) as hourly_rate_amount_percentage_value,
            trim(hourly_rate_amount_currency_code) as hourly_rate_amount_currency_code,
            trim(hourly_rate_amount_name) as hourly_rate_amount_name,
            trim(
                annual_rate_amount_name_short_name
            ) as annual_rate_amount_name_short_name,
            cast(
                annual_rate_amount_amount_value as number
            ) as annual_rate_amount_amount_value,
            cast(
                annual_rate_amount_percentage_value as number
            ) as annual_rate_amount_percentage_value,
            trim(annual_rate_amount_currency_code) as annual_rate_amount_currency_code,
            trim(annual_rate_amount_name) as annual_rate_amount_name,
            trim(
                pay_period_rate_amount_name_short_name
            ) as pay_period_rate_amount_name_short_name,
            cast(
                pay_period_rate_amount_amount_value as number
            ) as pay_period_rate_amount_amount_value,
            cast(
                pay_period_rate_amount_percentage_value as number
            ) as pay_period_rate_amount_percentage_value,
            trim(
                pay_period_rate_amount_currency_code
            ) as pay_period_rate_amount_currency_code,
            trim(pay_period_rate_amount_name) as pay_period_rate_amount_name,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
