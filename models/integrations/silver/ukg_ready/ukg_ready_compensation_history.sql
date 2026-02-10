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
        from {{ get_raw_source(company, sourcesystem, "COMPENSATION_HISTORY") }}
        {% if is_incremental() %}
            where
                cast(_loaded_at as timestamp_ntz) > (
                    select
                        dateadd(
                            day,
                            -1,
                            coalesce(max(_loaded_at), '1900-01-01'::timestamp_ntz)
                        )
                    from {{ this }}
                )
        {% endif %}
    ),

    cleaned as (
        select
            cast(id as int) as id,

            /* Employee object parsing */
            employee:account_id::int as employee_account_id,

            /* Cleaning scalar columns */
            cast(effective_from as date) as effective_from,
            cast(amount as float) as amount,
            cast(hourly_pay as float) as hourly_pay,
            trim(amount_period) as amount_period,
            cast(time as int) as time,
            trim(time_period) as time_period,
            cast(num_pp_in_year as int) as num_pp_in_year,
            _links,  -- OBJECT kept as-is
            trim(currency) as currency,
            current_timestamp() as silver_load_date,

        from source_data
    )

select *
from cleaned
