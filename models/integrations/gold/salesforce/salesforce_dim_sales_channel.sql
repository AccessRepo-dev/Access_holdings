{% set company = var('company', 'zeus') | lower %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce' and var('company','zeus') == 'zeus') }}

{{ config(
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
    FROM {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}  as O

)
select *
from source