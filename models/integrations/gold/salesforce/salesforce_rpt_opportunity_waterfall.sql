{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'rpt_opportunity_waterfall',
    incremental_strategy = 'merge',
    unique_key = ['opportunity_date','MAPPED_STAGE_NAME']
) }}

with cte as (
SELECT  
    date_trunc('month',cast(opportunity_date as date)) as opportunity_date,
    CASE WHEN m.MAPPED_STAGE_NAME = 'Opportunity' THEN 'New Opportunity' ELSE m.MAPPED_STAGE_NAME END AS MAPPED_STAGE_NAME ,  
    count(*) as opportunity_count,
     
from {{ref('salesforce_fact_opportunity')}} o
left join  {{ref ('salesforce_dim_stage_mapping')}} m on o.stage_key = m.stage_key
left join  {{ref ('salesforce_dim_opportunity') }} od on o.opportunity_id = od.opportunity_id 

WHERE  m.MAPPED_STAGE_NAME in ('Closed Won','Closed Lost','Opportunity')
GROUP BY  ALL 
),
cte1 as (
    select opportunity_date , sum(opportunity_count) as opportunity_count
    from cte
    group by opportunity_date
)

select c.opportunity_date ,
c.MAPPED_STAGE_NAME,
c.MAPPED_STAGE_NAME = 'New Opportunity' then c1.opportunity_count ELSE -1*c.opportunity_count END AS opportunity_count

from cte c
left join cte1 c1 on c.opportunity_date = c1.opportunity_date

