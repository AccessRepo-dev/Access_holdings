{% set location = var("location", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("location", "wagway") | lower) in ["wagway"],
        database=get_target_database(location),
        materialized="incremental",
        alias="dim_hr_location",
        incremental_strategy="merge",
        unique_key="dim_location_id",
    )
}}


WITH RECURSIVE org_hierarchy AS (
    SELECT ID, NAME, PARENT_ID, 1 AS level
    FROM {{ ref("ukg_ready_cost_center_store") }}
    WHERE PARENT_ID IS NULL
    UNION ALL
    SELECT c.ID, c.NAME, c.PARENT_ID, h.level + 1
    FROM {{ ref("ukg_ready_cost_center_store") }} c
    JOIN org_hierarchy h ON c.PARENT_ID = h.ID
)
SELECT DISTINCT
    ID AS dim_location_id,
    NAME AS location_name,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS gold_load_date
FROM org_hierarchy 
WHERE level = 3