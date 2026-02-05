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
        alias="dim_job_group",
        incremental_strategy="merge",
        unique_key="DIM_JOB_GROUP_ID",
    )
}}

with
    source as (
        select distinct
            md5(coalesce(id, '')) as dim_job_group_id,
            id as job_group_id,
            coalesce(classification_short_name, classification_long_name) as job_group,
            coalesce(name_short_name, name_long_name) as job_group_type,
            current_timestamp()::timestamp_ntz as gold_load_date
        from {{ ref("adp_workforce_now_classification") }}

    )
select *
from source