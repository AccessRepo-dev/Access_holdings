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
            cast(department_id as int) as dim_department_id,
            trim(department_code) as department_code,
            trim(department_name) as department_name,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("department_mapping") }}

    )
select *
from source