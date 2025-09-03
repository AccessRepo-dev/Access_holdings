{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'TRANSACTION_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'TRANSACTION') }}
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
        TRY_CAST(ID AS INT) AS TRANSACTION_ID,
        TRANSACTIONNUMBER AS TRANSACTION_NUMBER,
        TRIM(TRANID) AS TRANS_ID,
        TRIM(TYPE) AS TRANSACTION_TYPE,
        TRIM(STATUS) AS TRANSACTION_STATUS_ID,
        TRIM(BILLINGSTATUS) AS BILLING_STATUS,
        TRIM(SOURCE) AS SOURCE,
        TRIM(TITLE) AS TITLE,
        TRY_CAST(POSTINGPERIOD AS INT) AS POSTING_PERIOD_ID,
        TRY_CAST(ENTITY AS INT) AS INTERNAL_ENTITY_ID,
        TRY_CAST(EMPLOYEE AS INT) AS EMPLOYEE_ID,
        TRY_CAST(PAYMENTMETHOD AS INT) AS PAYMENT_METHOD_ID,
        TRY_CAST(CURRENCY AS INT) AS CURRENCY_ID,
        TRY_CAST(SOURCETRANSACTION AS INT) AS SOURCE_TRANSACTION_ID,
        AMOUNTUNBILLED AS AMOUNT_UNBILLED,
        EXCHANGERATE AS EXCHANGE_RATE,
        CAST(TRANDATE AS DATE) AS TRAN_DATE,
        CAST(CREATEDDATE AS DATE) AS CREATED_DATE,
        CAST(STARTDATE AS DATE) AS START_DATE,
        CAST(ENDDATE AS DATE) AS END_DATE,
        CAST(CLOSEDATE AS DATE) AS CLOSE_DATE,
        CAST(DUEDATE AS DATE) AS DUE_DATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        TRIM(BILLINGADDRESS) AS BILLING_ADDRESS_ID,
        TRIM(SHIPPINGADDRESS) AS SHIPPING_ADDRESS_ID,
        TRIM(EMAIL) AS SESSION_SHOP_EMAIL,
        TRIM(MEMO) AS MEMO,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned
