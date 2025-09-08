{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'CURRENCY_RATE_ID'
) }}

with source as (

    select
        ID as CURRENCY_RATE_ID,
        BASECURRENCY as BASE_CURRENCY,
        TRANSACTIONCURRENCY as TRANSACTION_CURRENCY,
        EFFECTIVEDATE as EFFECTIVE_DATE,
        EXCHANGERATE as EXCHANGE_RATE,
        LASTMODIFIEDDATE as LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'netsuite_currencyrate') }}
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
