{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    alias = 'dim_opportunity',
) }}

with source as (

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
    O.LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}  as O
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_LEAD') }}  as L 
        ON L.CONVERTED_OPPORTUNITY_ID = O.ID and  L.IS_ACTIVE = 1
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }}  A 
        ON A.ACCOUNT_ID = O.ACCOUNT_ID 
        and A.IS_ACTIVE = 1
    where O.IS_ACTIVE = 1

)
select *
from source