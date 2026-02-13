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
    unique_key = ['STAGE_DATE','MAPPED_STAGE_NAME', 'HUB']
) }}


WITH base_opp AS (
    SELECT
        fo.opportunity_id,
        fo.amount,
        fo.probability,
        fo.is_active,
        fo.rank,
        COALESCE(od.hub, 'Unknown') as hub,
        fo.dbt_valid_from,
        m.mapped_stage_name,
        m.stage_order,
        row_number() over(partition by fo.OPPORTUNITY_ID order by fo.DBT_VALID_FROM DESC) as desc_rank,
        DATE_TRUNC('month', od.opportunity_date)::date AS opportunity_month,
        DATE_TRUNC(
            'month',
            CASE
                WHEN m.mapped_stage_name = 'Closed Won'  THEN od.closed_won_date
                WHEN m.mapped_stage_name = 'Closed Lost' THEN od.closed_lost_date
            END
        )::date AS close_month
    FROM  {{ref('salesforce_fact_opportunity')}}  fo
    LEFT JOIN {{ref ('salesforce_dim_opportunity') }} od
        ON fo.opportunity_id = od.opportunity_id
    LEFT JOIN {{ref ('salesforce_dim_stage_mapping')}} m
        ON fo.STAGE_KEY = m.stage_key
),
period as (
    SELECT DISTINCT DATE_TRUNC('month', opportunity_date) AS START_OF_MONTH
    FROM {{ref('salesforce_dim_opportunity')}}
),
open_opp_wa as 
(
    SELECT  
        START_OF_MONTH,
        oo.HUB,
        sum(amount*probability/100) as amount
    from period p 
    left join  base_opp oo 
    on  oo.opportunity_month <= p.START_OF_MONTH 
    and  coalesce(oo.close_month, CURRENT_DATE()+1)  > p.START_OF_MONTH
    where oo.desc_rank = 1
    group by START_OF_MONTH ,HUB
) ,
opp_amt AS (
    SELECT
        opportunity_month AS stage_date,
        hub,
        SUM(amount) AS amount,
        SUM(amount * probability / 100) AS weighted_amount
    FROM base_opp
    WHERE rank = 1
    GROUP BY opportunity_month, hub
),
opp AS (
    SELECT
        'New Opportunity' AS mapped_stage_name,
        opportunity_month AS stage_date,
        hub,
        COUNT(DISTINCT opportunity_id) AS opp_count_old
    FROM base_opp
    GROUP BY opportunity_month, hub
), 
ranked_stages AS (
    SELECT
        opportunity_id,
        hub,
        amount,
        probability,
        is_active,
        mapped_stage_name,
        stage_order,
        close_month AS stage_date,
     
        LAG(amount) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_order, dbt_valid_from
        ) AS previous_amount,

        LAG(probability) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_order, dbt_valid_from
        ) AS previous_prob,

        LAG(mapped_stage_name) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_order, dbt_valid_from
        ) AS previous_stage_name
    FROM base_opp
),
closed_amt AS (
    SELECT
        mapped_stage_name,
        stage_date,
        hub,
        SUM(COALESCE(previous_amount, amount)* COALESCE(previous_prob, probability)/ 100) AS weighted_amount,
        SUM(amount) AS amount
    FROM ranked_stages
    WHERE mapped_stage_name IN ('Closed Won', 'Closed Lost')
      AND is_active = 1
    GROUP BY mapped_stage_name, stage_date, hub
),
closed AS (
    SELECT
        mapped_stage_name,
        close_month AS stage_date,
        hub,
        COUNT(DISTINCT opportunity_id) * -1 AS opp_count_old
    FROM base_opp
    WHERE mapped_stage_name IN ('Closed Won', 'Closed Lost')
    GROUP BY mapped_stage_name, close_month , hub
),
first_last_amounts AS (
    SELECT
        opportunity_id,
        opportunity_month,
        hub,
        FIRST_VALUE(amount) OVER (
            PARTITION BY opportunity_id
            ORDER BY dbt_valid_from
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS first_amount,
        LAST_VALUE(amount) OVER (
            PARTITION BY opportunity_id
            ORDER BY dbt_valid_from
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_amount
    FROM base_opp
),
delta_change as (SELECT 
    
    sum(coalesce(last_amount,0) - coalesce(first_amount,0)) as amount,
    0 as weighted_average,
    case when coalesce(last_amount,0) - coalesce(first_amount,0) > 0 then 'Increase' 
    when coalesce(last_amount,0) - coalesce(first_amount,0) < 0  THEN 'Decrease' 
    ELSE 'No Change'
    END  AS MAPPED_STAGE_NAME,
    opportunity_month as stage_date,
    hub,
    0 as opp_old_count
    FROM first_last_amounts
GROUP BY ALL
   
),
combined AS (
    SELECT 
        COALESCE(oa.amount, 0) as amount,
        COALESCE(wa.amount, 0) as weighted_amount,
        o.mapped_stage_name,
        o.stage_date,
        o.hub,
        o.opp_count_old
    FROM opp o 
    LEFT JOIN opp_amt oa ON oa.stage_date = o.stage_date AND oa.hub = o.hub
    LEFT JOIN open_opp_wa wa on o.stage_date = wa.start_of_month AND wa.hub = o.hub
    
    UNION ALL
    
    SELECT  
        COALESCE(cl.amount, 0) * -1 as amount,
        0 as weighted_amount,
        c.mapped_stage_name,
        c.stage_date,
        c.hub,
        c.opp_count_old
    FROM closed c 
    LEFT JOIN closed_amt cl ON cl.stage_date = c.stage_date
        AND c.mapped_stage_name = cl.mapped_stage_name
        AND c.hub = cl.hub
    
    UNION ALL
    
    SELECT 
        amount,
        0 as weighted_amount,
        mapped_stage_name,
        stage_date,
        hub,
        opp_old_count as opp_count_old
    FROM delta_change
    WHERE mapped_stage_name <> 'No Change'
)
SELECT 
    -- location_id,
    --sales_channel_id,
    SUM(amount) OVER (
        PARTITION BY hub,mapped_stage_name 
        ORDER BY stage_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS amount,
    weighted_amount,
    mapped_stage_name,
    stage_date,
    hub,
    SUM(opp_count_old) OVER (
        PARTITION BY  hub, mapped_stage_name 
        ORDER BY stage_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS opp_count
FROM combined

