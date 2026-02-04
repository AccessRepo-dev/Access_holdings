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
        from {{ get_raw_source(company, sourcesystem, "BENEFITS") }}
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
            cast(effective_from as date) as effective_from,
            cast(effective_to as date) as effective_to,
            cast(company_provided as boolean) as company_provided,
            cast(description as varchar) as description,
            current_timestamp() as silver_load_date,

        from source_data
    )

select *
from cleaned
