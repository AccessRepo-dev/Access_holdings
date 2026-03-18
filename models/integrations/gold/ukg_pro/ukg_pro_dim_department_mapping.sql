{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_department_mapping",
        incremental_strategy="merge",
        unique_key="department_id",
    )
}}

with
    source as (
        select
             DIM_DEPARTMENT_ID, 
             DEPARTMENT_NAME , 
             DIM_HR_DEPARTMENT_ID , 
             HR_DEPARTMENT_NAME ,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ source("playfly_ukg_pro_silver","playfly_department_mapping") }}

    )
select *
from source