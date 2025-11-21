{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none')  | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_currencyrate',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CURRENCY_RATE_ID'
) }}

with source as (

    select
        ID as DIM_CURRENCY_RATE_ID,
        BASECURRENCY as BASE_CURRENCY,
        TRANSACTIONCURRENCY as TRANSACTION_CURRENCY,
        EFFECTIVEDATE as EFFECTIVE_DATE,
        EXCHANGERATE as EXCHANGE_RATE,
        LASTMODIFIEDDATE as LAST_MODIFIED_DATE
    from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_CURRENCYRATE') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)

    {% if is_incremental() %}
        and LASTMODIFIEDDATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}
)
select *
from source
