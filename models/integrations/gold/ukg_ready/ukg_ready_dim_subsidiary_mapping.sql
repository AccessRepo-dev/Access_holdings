{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_subsidiary_mapping",
        incremental_strategy="merge",
        unique_key="subsidiary_id",
    )
}}

with
    source as (
        select
            DIM_SUBSIDIARY_ID,
            SUBSIDIARY_NAME,
            COMPANY_NAME,
            DIM_COMPANY_ID,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ source('wagway_ukg_ready_silver',"wagway_subsidiary_mapping") }}

    )
select *
from source