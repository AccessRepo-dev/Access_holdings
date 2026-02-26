{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_hr_location",
        incremental_strategy="merge",
        unique_key="DIM_LOCATION_ID",
    )
}}

with
    source as (
        select
            distinct
            hash(
                coalesce(home_work_location_address_city_name, '')
                || coalesce(home_work_location_address_country_code, '')
            ) as dim_location_id,
            null as location,
            null as state_key,
            home_work_location_address_city_name as city,
            home_work_location_address_country_code as country_code,
            null as state,
            home_work_location_address_postal_code as zip_or_postal_code,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("adp_workforce_now_work_assignment_history") }} wah

    )
select *
from source