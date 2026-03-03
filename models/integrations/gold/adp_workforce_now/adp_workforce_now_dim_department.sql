{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
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
            id as department_id,
            coalesce(name_short_name, name_long_name) as department_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("adp_workforce_now_organizational_unit") }}
        where lower(type_short_name) = 'department'

    )
select *
from source
