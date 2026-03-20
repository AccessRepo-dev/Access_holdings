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
            a.ID AS DIM_HR_LOCATION_ID,
            a.DESCRIPTION AS HR_LOCATION_NAME,
            b.RECORDNO AS DIM_LOCATION_ID,
            b.NAME AS LOCATION_NAME,
            
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref('ukg_pro_location') }} a
        full outer join {{source('spotless_silver','SAGE_LOCATION')}} b on b.LOCATIONID = a.LOCATION_GL_SEGMENT

    )
select *
from source