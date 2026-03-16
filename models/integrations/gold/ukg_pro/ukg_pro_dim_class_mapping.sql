{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_class_mapping",
        incremental_strategy="merge",
        unique_key="class_id",
    )
}}

with
    source as (
        select
            DIM_CLASS_ID ,
            CLASS_NAME,
            ORGANIZATION_LEVEL_NAME AS HR_CLASS_NAME,
            DIM_ORGANIZATION_ID AS DIM_HR_CLASS_ID,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ source("playfly_ukg_pro_silver","playfly_class_mapping") }} 

    )
select *
from source