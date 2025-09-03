{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'CURRENCY_RATE_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'CURRENCYRATE') }}
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS CURRENCY_RATE_ID,
        TRY_CAST(TRANSACTIONCURRENCY AS INT) AS TRANSACTION_CURRENCY_ID,
        TRY_CAST(EXCHANGERATE AS FLOAT) AS EXCHANGE_RATE,
        CAST(EFFECTIVEDATE AS DATE) AS EFFECTIVE_DATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned
