
{% set company = var('company', 'spotless') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_currency',
    materialized = 'table',
    unique_key = 'DIM_CURRENCY_ID'
) }}


 

with source as (
    SELECT
    DISTINCT
    per.RECORDNO AS DIM_PERIOD_ID,
    e.LOCATIONKEY AS FROM_SUBSIDIARY_ID,
    e.LOCATIONKEY AS TO_SUBSIDIARY_ID
FROM {{ ref('sage_gl_entry') }}  e
LEFT JOIN {{ ref('sage_reporting_period') }} per
    ON TRUNC(e.BATCH_DATE, 'MONTH') = per.START_DATE

        

)

SELECT *,    
    1 AS FROM_CURRENCY_ID,
    1 AS TO_CURRENCY_ID,
    1.0::FLOAT AS HISTORICALRATE,
    1.0::FLOAT AS AVERAGERATE,
    1.0::FLOAT AS CURRENTRATE 
FROM source