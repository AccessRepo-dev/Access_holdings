{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_hr_location",
        incremental_strategy="merge",
        unique_key="DIM_LOCATION_ID",
    )
}}

with
    source as (
        select distinct
            hash(location) as dim_location_id,
            -- location as location,
            case
                when regexp_like(trim(location), '^[0-9]{4}.*')
                then trim(regexp_replace(trim(location), '^[0-9]{4}\\s*', ''))
                else trim(location)
            end as location,
            null as state_key,
            null as city,
            null as country_code,
            null as state,
            null as zip_or_postal_code,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("paycom_employees") }}

    )
select *
from source
