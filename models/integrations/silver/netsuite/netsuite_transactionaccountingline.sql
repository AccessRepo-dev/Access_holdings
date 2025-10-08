{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'transactionaccountingline',
    incremental_strategy = 'merge',
    unique_key = ['TRANSACTION', 'TRANSACTIONLINE']
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'TRANSACTIONACCOUNTINGLINE') }}
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(TRANSACTION AS INT) AS TRANSACTION,
        TRY_CAST(TRANSACTIONLINE AS INT) AS TRANSACTIONLINE,
        TRY_CAST(ACCOUNT AS INT) AS ACCOUNT,
        TRY_CAST(ACCOUNTINGBOOK AS INT) AS ACCOUNTINGBOOK,
        TRIM(ACCOUNTTYPE) AS ACCOUNTTYPE,
        CASE WHEN POSTING='T' THEN TRUE ELSE FALSE END AS POSTING,
        AMOUNT AS AMOUNT,
        NETAMOUNT AS NETAMOUNT,
        AMOUNTPAID AS AMOUNTPAID,
        AMOUNTUNPAID AS AMOUNTUNPAID,
        EXCHANGERATE AS EXCHANGERATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned