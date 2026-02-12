{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        materialized = 'incremental',
        alias = 'rpt_opportunity_waterfall',
        incremental_strategy = 'merge',
        unique_key = ['STAGE_DATE','MAPPED_STAGE_NAME']
    )
}}



WITH base_opp AS (
    SELECT
        fo.opportunity_id,
        fo.amount,
        fo.probability,
        fo.is_active,
        fo.rank,
        fo.dbt_valid_from,
        m.mapped_stage_name,
        m.stage_order,
        DATE_TRUNC('month', od.opportunity_date)::date AS opportunity_month,
        DATE_TRUNC(
            'month',
            CASE
                WHEN m.mapped_stage_name = 'Closed Won'  THEN od.closed_won_date
                WHEN m.mapped_stage_name = 'Closed Lost' THEN od.closed_lost_date
            END
        )::date AS close_month
    FROM  {{ref('hubspot_fact_opportunity')}}  fo
    LEFT JOIN {{ref ('hubspot_dim_opportunity') }} od
        ON fo.opportunity_id = od.opportunity_id
    LEFT JOIN {{ref ('hubspot_dim_stage_mapping')}} m
        ON fo.STAGE_KEY = m.stage_key
),
opp_amt AS (
    SELECT
        opportunity_month AS stage_date,
        SUM(amount) AS amount,
        SUM(amount * probability / 100) AS weighted_amount
    FROM base_opp
    WHERE rank = 1
    GROUP BY opportunity_month
),
opp AS (
    SELECT
        'New Opportunity' AS mapped_stage_name,
        opportunity_month AS stage_date,
        COUNT(DISTINCT opportunity_id) AS opp_count_old
    FROM base_opp
    GROUP BY opportunity_month
), 
ranked_stages AS (
    SELECT
        opportunity_id,
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
        SUM(COALESCE(previous_amount, amount)* COALESCE(previous_prob, probability)/ 100) AS weighted_amount,
        SUM(amount) AS amount
    FROM ranked_stages
    WHERE mapped_stage_name IN ('Closed Won', 'Closed Lost')
      AND is_active = 1
    GROUP BY mapped_stage_name, stage_date
),
closed AS (
    SELECT
        mapped_stage_name,
        close_month AS stage_date,
        COUNT(DISTINCT opportunity_id) * -1 AS opp_count_old
    FROM base_opp
    WHERE mapped_stage_name IN ('Closed Won', 'Closed Lost')
    GROUP BY mapped_stage_name, close_month
),
first_last_amounts AS (
    SELECT
        opportunity_id,
        opportunity_month,
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
    0 as opp_old_count
    FROM first_last_amounts
GROUP BY ALL
   
),
combined AS (
    SELECT amount,weighted_amount,o.* FROM opp o 
    left join opp_amt oa on oa.stage_date = o.stage_date
    UNION ALL
    SELECT  amount * -1 ,weighted_amount * -1, c.* FROM closed c 
    left join closed_amt cl on cl.stage_date = c.stage_date
    and c.mapped_stage_name = cl.mapped_stage_name
    UNION ALL
    select * from delta_change
    where mapped_stage_name <> 'No Change'
    
)
SELECT 
    -- location_id,
    --sales_channel_id,
    SUM(amount) OVER (
        PARTITION BY mapped_stage_name 
        ORDER BY stage_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS amount,
     SUM(weighted_amount) OVER (
        PARTITION BY mapped_stage_name 
        ORDER BY stage_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS weighted_amount,
    mapped_stage_name,
    stage_date,
    SUM(opp_count_old) OVER (
        PARTITION BY  mapped_stage_name 
        ORDER BY stage_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS opp_count
FROM combined

