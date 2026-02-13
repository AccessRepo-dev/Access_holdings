{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_ready") == "ukg_ready") }}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="employee_account_id",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "TIME_ENTRIES") }}
        {% if is_incremental() %}
            where
                cast(_LOADED_AT as timestamp_ntz) > (
                    select
                        dateadd(
                            day,
                            -1,
                            coalesce(
                                max(_LOADED_AT), '1900-01-01'::timestamp_ntz
                            )
                        )
                    from {{ this }}
                )
        {% endif %}
    ),

    cleaned as (
        select
            -- Original columns (flat fields)
            cast(start_date as date) as start_date,
            cast(end_date as date) as end_date,

            -- Parse EMPLOYEE object
            employee:account_id::number as employee_account_id,

            -- Flatten TIME_ENTRIES array and parse nested fields
            time_entry.value:id::number as time_entry_id,
            time_entry.value:date::date as time_entry_date,
            time_entry.value:type::varchar as time_entry_type,
            time_entry.value:approval_status::varchar as approval_status,
            time_entry.value:total::number as total_milliseconds,
            time_entry.value:total::number / 3600000 as total_hours,  -- Convert to hours
            time_entry.value:calc_total::number as calc_total_milliseconds,
            time_entry.value:calc_total::number / 3600000 as calc_total_hours,
            time_entry.value:is_calc::boolean as is_calculated,
            time_entry.value:is_raw::boolean as is_raw,

            -- Parse nested TIME_OFF object within time_entries
            time_entry.value:time_off.id::number as time_off_id,

            -- Flatten COST_CENTERS array within time_entries
            cost_center.value:index::number as cost_center_index,
            cost_center.value:value.id::number as cost_center_id,

            -- Add metadata
            time_entry.index as time_entry_array_index,
            cost_center.index as cost_center_array_index,
            current_timestamp() as silver_load_date

        from
            source_data as raw,
            lateral flatten(input => raw.time_entries, outer => true) as time_entry,
            lateral flatten(
                input => time_entry.value:cost_centers, outer => true
            ) as cost_center

    )

select *
from cleaned
