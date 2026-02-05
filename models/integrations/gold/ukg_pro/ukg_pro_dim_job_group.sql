{% set company = var("company", "playfly") | lower %}
{{ config(enabled=var("sourcesystem", "ukg_pro") | lower == "ukg_pro") }}

{{
    config(
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
            md5(coalesce(job_family_code, '')) as dim_job_group_id,
            job_family_code as job_group_id,
            job_family_code as job_group,
            null as job_group_type,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("ukg_pro_job") }}
        where _fivetran_deleted = false

    )
select *
from source
