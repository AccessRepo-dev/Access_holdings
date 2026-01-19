{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_sales_channel',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source as (

    SELECT 
    distinct 
    md5(
        coalesce(O.LEAD_SOURCE,'')
        ) as ID,
    CASE WHEN O.LEAD_SOURCE is null then 'Unknown' ELSE O.LEAD_SOURCE END as SALES_CHANNEL,
    CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ ref('salesforce_opportunity_current') }}  as O

)
select *
from source