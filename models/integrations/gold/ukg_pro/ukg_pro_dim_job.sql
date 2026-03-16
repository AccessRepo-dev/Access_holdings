{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_job",
        incremental_strategy="merge",
        unique_key="job_key",
    )
}}

with
    source as (
        select
            id as dim_job_id,
            title as job_title,
            -- job_family_code as job_group,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_job") }}
        where _fivetran_deleted = false

    )
select *
from source