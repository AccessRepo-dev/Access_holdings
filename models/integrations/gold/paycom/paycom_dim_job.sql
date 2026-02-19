{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_job",
        incremental_strategy="merge",
        unique_key="dim_job_id",
    )
}}

with
    source as (
        select distinct
            hash(position_title) as dim_job_id,
            hash(position_title) as job_id,
            position_title as job_title,
            -- job_family_code as job_group,
            current_timestamp()::timestamp_ntz as gold_load_date
          from {{ ref("paycom_employees") }}

    )
select *
from source