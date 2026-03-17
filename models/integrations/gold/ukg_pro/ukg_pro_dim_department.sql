{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly","spotless"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_hr_department",
        incremental_strategy="merge",
        unique_key="dim_department_id",
    )
}}

with
    source as (
        select
            id as dim_department_id,
            description as department_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("ukg_pro_organization_level") }}
        where level in (1)
        and is_active = true

    )
select *
from source
