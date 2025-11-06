{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (

    select
        sqli.QUOTE_LINE_ITEM_ID AS SF_QUOTE_LINE_ITEM_ID,
        fq.quote_id,
        dp.product_id,
        sqli.QUANTITY,
        sqli.UNIT_PRICE
    FROM {{ get_silver_source(company, 'SALESFORCE_QUOTE_LINE_ITEM') }} sqli
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_QUOTE') }} fq
           ON sqli.quote_id = fq.quote_id
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_PRODUCT') }} dp
           ON sqli.product_id = dp.PRODUCT_ID


)
select *
from source