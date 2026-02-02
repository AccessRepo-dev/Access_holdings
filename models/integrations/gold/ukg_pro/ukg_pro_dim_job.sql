{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
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
            md5(coalesce(id, '')) as dim_job_id,
            id as job_id,
            title as job_title,
            job_family_code as job_group,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_job") }}
        where _fivetran_deleted = false

    )
select *
from source
