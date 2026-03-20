{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
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
            distinct 
            hash(department_description) as dim_department_id,
            department_description as department_name,
            current_timestamp()::timestamp_ntz as gold_load_date

        from {{ ref("paycom_employees") }}

    )
select *
from source