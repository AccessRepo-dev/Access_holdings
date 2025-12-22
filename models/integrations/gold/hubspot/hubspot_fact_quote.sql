{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly"]) }}

{{ config(
    enabled = false,
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'HS_QUOTE_ID',
    database = get_target_database(company),
    schema = 'gold',
    alias = 'fact_quote'
) }}

with source as (
    select
        sl.QUOTE_ID AS HS_QUOTE_ID,
        dd.DIM_DEAL_ID,
        sl.PROPERTY_HS_SENDER_COMPANY_NAME as SENDER_COMPANY_NAME,
        sl.PROPERTY_HS_QUOTE_PROGRESSION_STATUS as QUOTE_STATUS,
        sl.PROPERTY_HS_QUOTE_AMOUNT as QUOTE_AMOUNT,
        sl.PROPERTY_HS_CREATEDATE as CREATED_DATE_KEY,
        dd.CLOSE_DATE as CLOSED_DATE_KEY,
        current_timestamp() as GOLD_LOAD_DATE
    from {{ ref('hubspot_quote') }} as sl
    left join {{ ref('hubspot_dim_deal') }} as dd
        on sl.QUOTE_ID = dd.DIM_DEAL_ID
        -- and dd.IS_CURRENT = true
    left join {{ ref('hubspot_dim_date') }} as d1
        on d1.date_value = cast(sl.PROPERTY_HS_CREATEDATE as date)
    left join {{ ref('hubspot_dim_date') }} as d2
        on d2.date_value = cast(dd.CLOSE_DATE as date)
)

select
    HS_QUOTE_ID,
    DIM_DEAL_ID,
    SENDER_COMPANY_NAME,
    QUOTE_STATUS,
    QUOTE_AMOUNT,
    CREATED_DATE_KEY,
    CLOSED_DATE_KEY,
    GOLD_LOAD_DATE
from source

{% if is_incremental() %}
    where HS_QUOTE_ID not in (select HS_QUOTE_ID from {{ this }})
{% endif %}