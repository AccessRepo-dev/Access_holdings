{% set company = var("company", "zeus") | lower %}
{{
    config(
        enabled=var("sourcesystem", "adp_workforce_now") | lower
        == "adp_workforce_now"
    )
}}

{{
    config(
        database=get_target_database(company),
        materialized="incremental",
        alias="dim_job",
        incremental_strategy="merge",
        unique_key="DIM_JOB_ID",
    )
}}

with
    source as (
        select distinct
            md5(coalesce(job_title, job_short_name, job_long_name)) as dim_job_id,
            coalesce(job_title, job_short_name, job_long_name) as job_title,
            null as job_category,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("adp_workforce_now_work_assignment_history") }} wah
        where wah._fivetran_active = true and wah.primary_indicator = true

    )
select *
from source
