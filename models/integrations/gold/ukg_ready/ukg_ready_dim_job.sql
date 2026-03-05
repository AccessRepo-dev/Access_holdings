{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("company", "wagway") | lower) in ["wagway"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_job",
        incremental_strategy="merge",
        unique_key="dim_job_id",
    )
}}

with
    source as (
        select
            row_number() over (order by job_title) as dim_job_id,
            job_title,
            current_timestamp() as gold_load_date

        from {{ ref("ukg_ready_attendance") }} e

    )
select *
from source