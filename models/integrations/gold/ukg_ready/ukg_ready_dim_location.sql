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


    select
    c.id as dim_location_id,
    p.name as location_name,
     current_timestamp()::timestamp_ntz as gold_load_date
from {{ ref("ukg_ready_cost_center_department") }} c
left join {{ ref("ukg_ready_cost_center_department") }} p on c.parent_id = p.id
-- left join {{ ref("ukg_ready_cost_center_department") }} pp on p.parent_id = pp.id
-- left join {{ ref("ukg_ready_cost_center_department") }} ppp on pp.parent_id = ppp.id
 
