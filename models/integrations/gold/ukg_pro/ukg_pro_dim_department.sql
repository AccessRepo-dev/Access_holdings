{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
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
            md5(coalesce(id, '')) as dim_department_id,
            id as department_id,
            description as department_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("ukg_pro_organization_level") }}
        where level in (3)
        and is_active = true

    )
select *
from source
