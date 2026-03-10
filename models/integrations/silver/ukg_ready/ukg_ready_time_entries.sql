{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
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
            employee_account_id::number as employee_account_id,
 
            -- Flatten TIME_ENTRIES array and parse nested fields
            time_entries_id::number as time_entries_id,
            time_entries_date::date as time_entries_date,
            TIME_ENTRIES_END_TIME::timestamp as TIME_ENTRIES_END_TIME, -- Need to handle blank
            TIME_ENTRIES_START_TIME::timestamp as TIME_ENTRIES_START_TIME,-- Need to handle blank
            time_entries_type::varchar as time_entries_type,
            TIME_ENTRIES_APPROVAL_STATUS::varchar as TIME_ENTRIES_APPROVAL_STATUS,
            TIME_ENTRIES_CALC_START_TIME::timestamp as TIME_ENTRIES_CALC_START_TIME, 
            TIME_ENTRIES_CALC_END_TIME::timestamp as TIME_ENTRIES_CALC_END_TIME,
            TIME_ENTRIES_CALC_TOTAL::number as TIME_ENTRIES_CALC_TOTAL,
            TIME_ENTRIES_CALC_TOTAL::number / 3600000 as TIME_ENTRIES_CALC_TOTAL_HOURS,  -- Convert to hours
            TIME_ENTRIES_TOTAL::number as TIME_ENTRIES_TOTAL,
            TIME_ENTRIES_TOTAL::number / 3600000 as TIME_ENTRIES_TOTAL_HOURS,
            TIME_ENTRIES_IS_CALC::boolean as is_calculated,
            TIME_ENTRIES_IS_RAW::boolean as is_raw,
 
            -- Parse nested TIME_OFF object within time_entries
            TIME_ENTRIES_TIME_OFF_ID:time_off.id::number as TIME_ENTRIES_TIME_OFF_ID,
 
            -- Flatten COST_CENTERS array within time_entries
            TIME_ENTRIES_COST_CENTERS_INDEX:index::number as TIME_ENTRIES_COST_CENTERS_INDEX,
            TIME_ENTRIES_COST_CENTERS_VALUE_ID::number as TIME_ENTRIES_COST_CENTERS_VALUE_ID,
 
            current_timestamp() as silver_load_date
 
        from
            source_data

    )

select *
from cleaned
