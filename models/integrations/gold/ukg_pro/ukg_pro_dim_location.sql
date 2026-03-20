{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "spotless") | lower) in ["spotless"],
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
           
            a.ID AS DIM_LOCATION_ID,
            a.DESCRIPTION AS LOCATION_NAME,
           
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_location") }} a

    )
select *
from source
