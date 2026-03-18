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


 SELECT 
    job.ID AS dim_job_id,
    dep.NAME AS job_title,
    CURRENT_TIMESTAMP() AS gold_load_date
FROM {{ ref("ukg_ready_cost_center_org") }} job
LEFT JOIN {{ ref("ukg_ready_cost_center_org") }} dep ON job.PARENT_ID = dep.ID
WHERE job.ID NOT IN (
    SELECT DISTINCT PARENT_ID 
    FROM {{ ref("ukg_ready_cost_center_org") }} 
    WHERE PARENT_ID IS NOT NULL
)



