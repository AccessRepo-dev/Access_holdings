{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="time_card_id",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "WORKER_TIME_CARD_ENTRY_TOTAL") }}
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
            cast(day_entry_index as number) as day_entry_index,
            trim(time_card_id) as time_card_id,
            trim(time_entry_id) as time_entry_id,
            cast(index as number) as index,
            trim(pay_short_name) as pay_short_name,
            trim(pay_long_name) as pay_long_name,
            trim(pay_subdivision_type) as pay_subdivision_type,
            cast(pay_effective_date as date) as pay_effective_date,
            cast(rate_base_multiplier_value as number) as rate_base_multiplier_value,
            cast(rate_amount_value as float) as rate_amount_value,
            trim(rate_currency_code) as rate_currency_code,
            trim(time_duration) as time_duration,
            trim(pay) as pay,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
