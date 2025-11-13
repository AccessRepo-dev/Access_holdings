
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_currency',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CURRENCY_ID'
) }}


 

with source as (
    SELECT
    DISTINCT
    per.RECORDNO AS DIM_PERIOD_ID,
    e.LOCATIONKEY AS FROM_SUBSIDIARY_ID,
    e.LOCATIONKEY AS TO_SUBSIDIARY_ID,

 
FROM {{ get_silver_source(company, 'GL_ENTRY') }}  e
LEFT JOIN {{ get_silver_source(company, 'REPORTING_PERIOD') }} per
    ON TRUNC(e.BATCH_DATE, 'MONTH') = per.START_DATE

        

)

SELECT *,    
    1 AS FROM_CURRENCY_ID,
    1 AS TO_CURRENCY_ID,
    1 AS HISTORICALRATE,
    1 AS AVERAGERATE,
    1 AS CURRENTRATE 
FROM source