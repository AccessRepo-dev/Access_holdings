{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
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
            DIM_CLASS_ID,
            CLASS_NAME,
            PARENT_CLASS_NAME,
            ORGANIZATION_LEVEL_NAME,
            DIM_ORGANIZATION_ID,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("class_mapping") }}

    )
select *
from source