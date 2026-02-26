{% set company = var("company", "amh") %}
{% set sourcesystem = var("sourcesystem", "paycom") %}


{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        alias=sourcesystem ~ "_EMPLOYEE_SENSITIVE",
        schema="silver",
        unique_key="eecode",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns",
    )
}}


with
    raw as (
        select *
        from {{ get_raw_source(company, sourcesystem, "EMPLOYEE_SENSITIVE") }}

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

            -- TEXT (trim)
            trim(eecode) as eecode,
            
            cast(annual_salary as float) as annual_salary,
            cast(hourly_salary as float) as hourly_salary,
            cast(last_pay_rate as float) as last_pay_rate,

            trim(pay_class) as pay_class,
            trim(pay_frequency) as pay_frequency,

            -- TIMESTAMP_TZ
            trim(_etl_batch_id) as _etl_batch_id,
            cast(_deleted_at as timestamp_tz) as _deleted_at,
            current_timestamp()::timestamp_ntz as silver_load_date,
            _loaded_at::timestamp_ntz as raw_load_date

        from raw
    )

select *
from cleaned