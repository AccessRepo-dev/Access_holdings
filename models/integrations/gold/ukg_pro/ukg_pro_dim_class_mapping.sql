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
            md5(coalesce(class_code, '')) as dim_department_id,
            trim(class_code) as class_code,
            trim(class_name) as class_name,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("class_mapping") }}

    )
select *
from source