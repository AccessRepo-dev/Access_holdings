{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "paycom") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_job_group",
        incremental_strategy="merge",
        unique_key="dim_job_group_id",
    )
}}

with
    source as (
        select distinct
            hash(position_family) as dim_job_group_id,
            position_family as job_group,
            null as job_group_type,
            current_timestamp()::timestamp_ntz as gold_load_date
          from {{ ref("paycom_employees") }}

    )
select *
from source