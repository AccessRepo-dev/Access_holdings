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
        from {{ get_raw_source(company, sourcesystem, "WORKER_TIME_CARD_TIME_ENTRY") }}
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
            trim(entry_id) as entry_id,
            trim(entry_type_short_name) as entry_type_short_name,
            trim(entry_type_long_name) as entry_type_long_name,
            trim(entry_type_subdivision_type) as entry_type_subdivision_type,
            cast(entry_type_effective_date as date) as entry_type_effective_date,
            cast(entry_date as date) as entry_date,
            cast(
                start_period_start_date_time as timestamp_tz
            ) as start_period_start_date_time,
            cast(end_period_end_date_time as timestamp_tz) as end_period_end_date_time,
            trim(time_duration) as time_duration,
            trim(entry_status_short_name) as entry_status_short_name,
            trim(entry_status_long_name) as entry_status_long_name,
            trim(entry_status_subdivision_type) as entry_status_subdivision_type,
            cast(entry_status_effective_date as date) as entry_status_effective_date,
            trim(entry_type) as entry_type,
            trim(entry_status) as entry_status,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            current_timestamp() as silver_load_date
        from source_data
    )

select *
from cleaned
