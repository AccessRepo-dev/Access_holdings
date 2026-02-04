{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_ready") == "ukg_ready") }}

{{
    config(
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
            cast(username as varchar) as username,
            cast(first_name as varchar) as first_name,
            cast(last_name as varchar) as last_name,
            cast(primary_account_id as number) as primary_account_id,
            cast(ein_name as varchar) as ein_name,
            cast(_links as varchar) as _links,
            cast(status as varchar) as status,
            cast(dates as varchar) as dates,
            dates:"hired"::date as hired_date,
            dates:"started"::date as started_date,
            dates:"terminated"::date as terminated_date,
            current_timestamp() as silver_load_date,

        from source_data
    )

select *
from cleaned
