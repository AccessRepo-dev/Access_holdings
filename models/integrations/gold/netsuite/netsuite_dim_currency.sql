
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    alias = 'dim_currency',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID'
) }}

with source as (
    select
        ID AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        POSTINGPERIOD AS DIM_PERIOD_ID,
        FROMSUBSIDIARY AS FROM_SUBSIDIARY_ID,
        TOSUBSIDIARY AS TO_SUBSIDIARY_ID,
        FROMCURRENCY AS FROM_CURRENCY_ID,
        TOCURRENCY AS TO_CURRENCY_ID,
        HISTORICALRATE,
        AVERAGERATE,
        CURRENTRATE
    from {{ get_silver_source(company, 'CONSOLIDATEDEXCHANGERATE') }}
    WHERE TOCURRENCY=1

)
select *
from source