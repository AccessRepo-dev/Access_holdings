{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (

    SELECT 
    B.ID as OPPORTUNITY_ID,
    B.NAME AS OPPORTUNITY_NAME,
    B.CREATED_DATE as OPPORTUNITY_DATE,
    -- B.STAGE_NAME as STAGE_NAME,
    A.LEAD_SOURCE as SALES_CHANNEL,
    A.INDUSTRY as PRODUCT_CATEGORY,
    A.CITY as LOCATION,
    -- A.OWNER_ID as MANAGER,
    NULL AS SALES_ESTIMATE,
    -- B.AMOUNT as AMOUNT,
    -- B.PROBABILITY,
    -- B.CLOSE_DATE,
    -- B.IS_WON as status,
    -- B.IS_CLOSED,
    B.LAST_MODIFIED_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}  as B 
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_LEAD') }}  as A 
        ON A.CONVERTED_OPPORTUNITY_ID = B.ID and A.IS_ACTIVE = 1 and B.IS_ACTIVE = 1

)
select *
from source