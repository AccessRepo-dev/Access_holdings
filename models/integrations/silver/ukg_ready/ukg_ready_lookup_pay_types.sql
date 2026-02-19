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
        from {{ get_raw_source(company, sourcesystem, "LOOKUP_PAY_TYPES") }}
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
            trim(name) as name,
            current_timestamp() as silver_load_date,

        from source_data
    )

select *
from cleaned