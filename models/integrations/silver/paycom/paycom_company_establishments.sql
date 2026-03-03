{% set company = var("company", "amh") %}
{% set sourcesystem = var("sourcesystem", "paycom") %}


{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"] and (var("company", "amh") | lower) in ["amh"],
        database = get_target_database(company),
        alias = sourcesystem ~ '_COMPANY_ESTABLISHMENTS',
        schema="silver",
        unique_key="ESTABLISHMENTID",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns"
    )
}}


with
    raw as (
        select *
        from {{ get_raw_source(company, sourcesystem, 'COMPANY_ESTABLISHMENTS') }}

    {% if is_incremental()%}
    where 
        cast(RAW_LOAD_DATE as timestamp_ntz) > (select dateadd(day, -1, coalesce(max(RAW_LOAD_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}

    ),
    cleaned as (
        
        SELECT
            ESTABLISHMENTID,
            TRIM(DESCRIPTION) AS DESCRIPTION,
            TRIM(ADDRESS) AS ADDRESS,
            TRIM(CITY) AS CITY,
            TRIM(STATE) AS STATE,
            CAST(ZIPCODE AS NUMBER) AS ZIPCODE,
            TRIM(COUNTRY) AS COUNTRY,
            f.VALUE:: INT AS LOCATIONID,  
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            _LOADED_AT::TIMESTAMP_NTZ AS RAW_LOAD_DATE
        FROM raw
            , LATERAL FLATTEN(input => LOCATIONIDS) f

    )

select *
from cleaned
