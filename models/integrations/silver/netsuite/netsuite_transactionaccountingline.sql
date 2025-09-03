{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['TRANSACTION_ID', 'TRANSACTION_LINE_ID']
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'TRANSACTIONACCOUNTINGLINE') }}
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
        TRY_CAST(TRANSACTION AS INT) AS TRANSACTION_ID,
        TRY_CAST(TRANSACTIONLINE AS INT) AS TRANSACTION_LINE_ID,
        TRY_CAST(ACCOUNT AS INT) AS ACCOUNT_ID,
        TRY_CAST(ACCOUNTINGBOOK AS INT) AS ACCOUNTING_BOOK_ID,
        TRIM(ACCOUNTTYPE) AS ACCOUNT_TYPE,
        TRIM(POSTING) AS TRANSACTION_ACCOUNTING_POSTING_FLAG,
        AMOUNT AS AMOUNT,
        NETAMOUNT AS NET_AMOUNT,
        AMOUNTPAID AS AMOUNT_PAID,
        AMOUNTUNPAID AS AMOUNT_UN_PAID,
        EXCHANGERATE AS EXCHANGE_RATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned