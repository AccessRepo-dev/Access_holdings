{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}
{{ config(enabled=var("sourcesystem", "adp_workforce_now") == "adp_workforce_now") }}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="time_card_id",
    )
}}

with
    source_data as (
        select *
        from
            {{
                get_raw_source(
                    company, sourcesystem, "WORKER_TIME_CARD_HOME_LABOR_ALLOCATION"
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
            trim(time_card_id) as time_card_id,
            cast(index as number) as index,
            trim(allocation_code_value) as allocation_code_value,
            trim(allocation_type_code_value) as allocation_type_code_value,
            trim(allocation_type_short_name) as allocation_type_short_name,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
