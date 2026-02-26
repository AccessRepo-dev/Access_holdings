{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
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

            id as dim_location_id,
            null as location,
            md5(coalesce(state, '')) as STATE_KEY,
            city,
            country_code,
            state,
            zip_or_postal_code,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_location") }}
        where is_active = true and _fivetran_deleted = false

    )
select *
from source