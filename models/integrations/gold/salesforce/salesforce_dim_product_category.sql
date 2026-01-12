{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_product_category',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source as (

    SELECT 
    distinct 
    md5(
        coalesce(SYSTEM_SUB_TYPE_C,'')
        ) as ID,
    -- CASE WHEN L.INDUSTRY IS NULL THEN 'Unknown' ELSE L.INDUSTRY END as PRODUCT_CATEGORY,
    CASE 
    WHEN SYSTEM_SUB_TYPE_C IS NULL THEN 'Unknown'
    WHEN SYSTEM_SUB_TYPE_C like '%-%' THEN SPLIT_PART(SYSTEM_SUB_TYPE_C, '-', 2) 
    ELSE SYSTEM_SUB_TYPE_C END as PRODUCT_CATEGORY,
    CONCAT('SALESFORCE_','{{company | upper}}') as SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ ref('salesforce_opportunity_current') }}  as O

)
select *
from source