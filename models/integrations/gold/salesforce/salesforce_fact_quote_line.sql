{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    enabled = false,
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (

    select
        sqli.ID_DATE_KEY,
        sqli.QUOTE_LINE_ITEM_ID AS SF_QUOTE_LINE_ITEM_ID,
        fq.quote_id,
        dp.product_id,
        sqli.QUANTITY,
        sqli.UNIT_PRICE,
        sqli.IS_ACTIVE
    FROM {{ get_silver_source(company, 'SALESFORCE_QUOTE_LINE_ITEM') }} sqli
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_QUOTE') }} fq
           ON sqli.quote_id = fq.quote_id AND fq.IS_ACTIVE = 1
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_PRODUCT') }} dp
           ON sqli.product_id = dp.PRODUCT_ID AND dp.IS_ACTIVE = 1


)
select *
from source