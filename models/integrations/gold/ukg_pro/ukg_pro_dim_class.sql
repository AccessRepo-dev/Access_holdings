{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_hr_class",
        incremental_strategy="merge",
        unique_key="dim_class_id",
    )
}}

with
    source as (
        select
            md5(coalesce(id, '')) as dim_class_id,
            id as class_id,
            description as class_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("ukg_pro_organization_level") }}
        where level in (1)
        and is_active = true

    )
select *
from source
