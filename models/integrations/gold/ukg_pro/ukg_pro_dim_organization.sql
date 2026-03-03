{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_organization",
        incremental_strategy="merge",
        unique_key="DIM_ORGANIZATION_LEVEL_ID",
    )
}}

with
    source as (
        select
            md5(coalesce(id, '') || coalesce(level, '') ) as dim_organization_level_id,
            id as dim_organization_id,
            level as organization_level,
            level_description as organization_level_description,
            description as organization_level_name,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_organization_level") }}
        where is_active = true

    )
select *
from source
