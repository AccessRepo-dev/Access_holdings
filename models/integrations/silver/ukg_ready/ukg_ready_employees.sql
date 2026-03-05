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
        from {{ get_raw_source(company, sourcesystem, "EMPLOYEES") }}
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
            try_cast(employee_id as varchar) as employee_id,
            cast(primary_account_id as number) as primary_account_id,
            cast(ein_name as varchar) as ein_name,
            cast(status as varchar) as status,
            dates_hired as hired_date,
            dates_started as started_date,
            dates_terminated as terminated_date,
            current_timestamp() as silver_load_date
        from source_data
    )

select *
from cleaned
