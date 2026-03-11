{% set department = var("department", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_ready") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_ready") | lower) in ["ukg_ready"]
        and (var("department", "wagway") | lower) in ["wagway"],
        database=get_target_database(department),
        materialized="incremental",
        alias="dim_hr_department",
        incremental_strategy="merge",
        unique_key="dim_department_id",
    )
}}





with level4 as 
(
    select
    DISTINCT
    ppp.id,
    ppp.name
from {{ ref("ukg_ready_cost_center_department") }} c
left join {{ ref("ukg_ready_cost_center_department") }} p on c.parent_id = p.id
left join {{ ref("ukg_ready_cost_center_department") }} pp on p.parent_id = pp.id
left join {{ ref("ukg_ready_cost_center_department") }} ppp on pp.parent_id = ppp.id
 
),
level3 as 
(
    select
    DISTINCT
    pp.id
from {{ ref("ukg_ready_cost_center_department") }} c
left join {{ ref("ukg_ready_cost_center_department") }} p on c.parent_id = p.id
left join {{ ref("ukg_ready_cost_center_department") }} pp on p.parent_id = pp.id
where pp.id  not in (select id from level4 where id is not null )
 
),
level2 as
(select
    DISTINCT
    p.id ,
    p.name 
from {{ ref("ukg_ready_cost_center_department") }} c
left join {{ ref("ukg_ready_cost_center_department") }} p on c.parent_id = p.id
where p.id not in (select  id from level3) and  p.id not in (select  id from level4 where id is not null)
)
select
    DISTINCT
    c.id as dim_department_id,
    SPLIT_PART(name, '(', 1) as department_name,
    current_timestamp() as gold_load_date
from {{ ref("ukg_ready_cost_center_department") }} c
where c.id not in (select  id from level2) and  c.id not in (select  id from level4 where id is not null) and c.id not in (select  id from level3)

