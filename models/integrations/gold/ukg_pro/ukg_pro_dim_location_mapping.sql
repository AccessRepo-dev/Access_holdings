{% set company = var("company", "spotless") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "spotless") | lower) in ["spotless"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_location_mapping",

    )
}}

with
    source as (
        select
            DIM_HR_LOCATION_ID,
            HR_LOCATION_NAME,
            DIM_LOCATION_ID,
            LOCATION_NAME,
            
            current_timestamp()::timestamp_ntz as gold_load_date
        from  {{ source("spotless_ukg_pro_silver","spotless_location_mapping") }}  b 

    )
select *
from source