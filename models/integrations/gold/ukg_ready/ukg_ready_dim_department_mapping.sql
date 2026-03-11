{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_department_mapping",
        incremental_strategy="merge",
        unique_key="dim_department_id",
    )
}}

with
    source as (
        select
            *,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ source('wagway_ukg_ready_silver',"wagway_department_mapping") }}

    )
select *
from source