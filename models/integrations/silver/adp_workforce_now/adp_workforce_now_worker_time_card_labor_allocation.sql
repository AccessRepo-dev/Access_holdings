{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}
{{ config(enabled=var("sourcesystem", "adp_workforce_now") == "adp_workforce_now") }}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="DAY_ENTRY_INDEX",
    )
}}

with
    source_data as (
        select *
        from
            {{
                get_raw_source(
                    company, sourcesystem, "WORKER_TIME_CARD_LABOR_ALLOCATION"
                )
            }}
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
            trim(allocation_short_name) as allocation_short_name,
            trim(allocation_long_name) as allocation_long_name,
            trim(allocation_subdivision_type) as allocation_subdivision_type,
            cast(allocation_effective_date as date) as allocation_effective_date,
            trim(allocation_type_short_name) as allocation_type_short_name,
            trim(allocation_type_long_name) as allocation_type_long_name,
            trim(allocation_type_subdivision_type) as allocation_type_subdivision_type,
            cast(
                allocation_type_effective_date as date
            ) as allocation_type_effective_date,
            trim(allocation) as allocation,
            trim(allocation_type) as allocation_type,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
