{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    alias = 'dim_opportunity',
) }}

with stage_dates as (

SELECT 
opportunity_id,
old_value,
SO.MAPPED_STAGE_NAME as old_mapped_value,
new_value,
SN.MAPPED_STAGE_NAME as new_mapped_value,
created_date 
FROM ZEUS_RAW.SALESFORCE.OPPORTUNITY_FIELD_HISTORY O 
LEFT JOIN ZEUS_DEV.GOLD.DIM_STAGE_MAPPING SO ON trim(O.OLD_VALUE) = SO.STAGE_NAME
LEFT JOIN ZEUS_DEV.GOLD.DIM_STAGE_MAPPING SN ON trim(O.NEW_VALUE) = SN.STAGE_NAME
where field = 'StageName'
and old_mapped_value <> new_mapped_value
order by opportunity_id, created_date
)

, stage_dates_by_opp as (
SELECT
    opportunity_id,

    MIN(CASE WHEN lower(new_mapped_value) = 'opportunity'
             THEN created_date END) AS opportunity_date,

    MIN(CASE WHEN lower(new_mapped_value) = 'proposal requested'
             THEN created_date END) AS proposal_requested_date,

    MIN(CASE WHEN lower(new_mapped_value) = 'proposal sent'
             THEN created_date END) AS proposal_sent_date,

    MIN(CASE WHEN lower(new_mapped_value) = 'negotiation'
             THEN created_date END) AS negotiation_date,

    MIN(CASE WHEN lower(new_mapped_value) = 'closed won'
             THEN created_date END) AS closed_won_date,

    MIN(CASE WHEN lower(new_mapped_value) = 'closed lost'
             THEN created_date END) AS closed_lost_date

FROM
    stage_dates
GROUP BY
    opportunity_id
    )




, source as (

    SELECT 
    O.ID as OPPORTUNITY_ID,
    O.NAME AS OPPORTUNITY_NAME,
    O.CREATED_DATE as OPPORTUNITY_DATE,
    -- B.STAGE_NAME as STAGE_NAME,
    md5(
        coalesce(O.LEAD_SOURCE,'')
        ) as SALES_CHANNEL_ID,
    -- O.LEAD_SOURCE as SALES_CHANNEL,
    md5(
        coalesce(L.INDUSTRY,'')
        ) as PRODUCT_CATEGORY_ID,
    -- L.INDUSTRY as PRODUCT_CATEGORY,
    md5(
        coalesce(A.BILLING_CITY,'') || '|' ||
        coalesce(A.BILLING_STATE,'') || '|' ||
        coalesce(A.BILLING_COUNTRY,'')
        ) as LOCATION_ID,
    -- A.OWNER_ID as MANAGER,
    -- NULL AS SALES_ESTIMATE,
    -- B.AMOUNT as AMOUNT,
    -- B.PROBABILITY,
    O.CLOSE_DATE,
    O.IS_WON as IS_WON,
    O.IS_CLOSED,
    CASE WHEN IS_WON = 1 THEN COALESCE(SO.proposal_requested_date,
             SO.proposal_sent_date,
             SO.negotiation_date,
             SO.closed_won_date,
             O.CLOSE_DATE) 
             ELSE 
             COALESCE(SO.proposal_requested_date,
             SO.proposal_sent_date,
             SO.negotiation_date,
             SO.closed_lost_date,
             O.CLOSE_DATE) END
             AS proposal_requested_date,
    CASE WHEN IS_WON = 1 THEN COALESCE(
             SO.proposal_sent_date,
             SO.negotiation_date,
             SO.closed_won_date,
             O.CLOSE_DATE) 
             ELSE 
             COALESCE(
             SO.proposal_sent_date,
             SO.negotiation_date,
             SO.closed_lost_date,
             O.CLOSE_DATE) END
             AS proposal_sent_date,  
    CASE WHEN IS_WON = 1 THEN COALESCE(
             SO.negotiation_date,
             SO.closed_won_date,
             O.CLOSE_DATE) 
             ELSE 
             COALESCE(
             SO.negotiation_date,
             SO.closed_lost_date,
             O.CLOSE_DATE) END
             AS negotiation_date,

    CASE WHEN IS_WON = 1 THEN COALESCE(SO.closed_won_date,
             O.CLOSE_DATE) ELSE NULL END AS closed_won_date,
    CASE WHEN IS_WON = 0 THEN COALESCE(SO.closed_lost_date,
             O.CLOSE_DATE) ELSE NULL END AS closed_lost_date,
    O.LAST_MODIFIED_DATE,
    CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}  as O
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_LEAD') }}  as L 
        ON L.CONVERTED_OPPORTUNITY_ID = O.ID and  L.IS_ACTIVE = 1
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }}  A 
        ON A.ACCOUNT_ID = O.ACCOUNT_ID 
        and A.IS_ACTIVE = 1
    LEFT JOIN stage_dates_by_opp SO ON SO.opportunity_id = O.ID
    where O.IS_ACTIVE = 1

)
select *
from source