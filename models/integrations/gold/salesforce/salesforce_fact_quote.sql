{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'QUOTE_ID'
) }}

with source as (

    select
        sq.QUOTE_ID,
        fo.ID AS opportunity_id,
        da.ACCOUNT_ID,
        sq.grand_total as TOTAL_AMOUNT,
        SQ.CREATED_DATE,
    FROM {{ get_silver_source(company, 'SALESFORCE_QUOTE') }} sq
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }} fo 
           ON sq.opportunity_id = fo.ID
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }} da 
           ON sq.account_id = da.account_id


)
select *
from source