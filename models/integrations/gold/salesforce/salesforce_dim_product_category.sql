{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce') }}
{{ config(enabled = var('company', 'zeus') == 'zeus') }}

{{ config(
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
        coalesce(L.INDUSTRY,'')
        ) as ID,
    CASE WHEN L.INDUSTRY IS NULL THEN 'Unknown' ELSE L.INDUSTRY END as PRODUCT_CATEGORY,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
    FROM {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}  as O
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_LEAD') }}  as L 
        ON L.CONVERTED_OPPORTUNITY_ID = O.ID and  L.IS_ACTIVE = 1

)
select *
from source