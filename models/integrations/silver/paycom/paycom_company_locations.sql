{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database = get_target_database(company),
        alias = sourcesystem ~ '_COMPANY_LOCATIONS',
        schema="silver",
        unique_key="LOCATIONID",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns"
    )
}}


with
    raw as (
        select *
        from {{ get_raw_source(company, sourcesystem, 'COMPANY_LOCATIONS') }}

    {% if is_incremental()%}
    where 
        cast(RAW_LOAD_DATE as timestamp_ntz) > (select dateadd(day, -1, coalesce(max(RAW_LOAD_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}

    ),
    cleaned as (
        select
            LOCATIONID,
            TRIM(DESCRIPTION) AS DESCRIPTION,
            TRIM(ADDRESS) AS ADDRESS,
            TRIM(CITY) AS CITY,
            TRIM(STATE) AS STATE,
            CAST(ZIPCODE AS NUMBER) AS ZIPCODE,
            TRIM(COUNTRY) AS COUNTRY , 
            current_timestamp()::timestamp_ntz as silver_load_date,
            _LOADED_AT::timestamp_ntz  AS RAW_LOAD_DATE

        from raw
    )

select *
from cleaned
