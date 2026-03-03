{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "PAY_PERIOD_PROFILES") }}
        {% if is_incremental() %}
            where
                cast(date_time_changed as timestamp_ntz) > (
                    select
                        dateadd(
                            day,
                            -1,
                            coalesce(
                                max(date_time_changed), '1900-01-01'::timestamp_ntz
                            )
                        )
                    from {{ this }}
                )
        {% endif %}
    ),

    cleaned as (
        select
            cast(id as number) as id,
            cast(name as varchar) as name,
            cast(active as boolean) as active,
            cast(effective_from as date) as effective_from,
            cast(period_type as varchar) as period_type,
            period_type:"type"::string as period_type_type,
            period_type:"params":"week_day"::string as week_day,
            period_type:"params":"num_weeks"::number as num_weeks,
            period_type:"params":"start_date"::date as start_date,
            current_timestamp() as silver_load_date,

        from source_data
    )

select *
from cleaned
