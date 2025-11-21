{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'TRANSACTION') }}
    {% if is_incremental() %}
    where 
        cast(LASTMODIFIEDDATE as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS ID,
        TRANSACTIONNUMBER AS TRANSACTIONNUMBER,
        TRIM(TRANID) AS TRANID,
        TRIM(TYPE) AS TYPE,
        TRIM(STATUS) AS STATUS,
        TRY_CAST(CUSTOMTYPE AS INT) AS CUSTOMTYPE,
        TRIM(BILLINGSTATUS) AS BILLINGSTATUS,
        TRIM(SOURCE) AS SOURCE,
        TRIM(TITLE) AS TITLE,
        TRY_CAST(POSTINGPERIOD AS INT) AS POSTINGPERIOD,
        TRY_CAST(ENTITY AS INT) AS ENTITY,
        TRY_CAST(EMPLOYEE AS INT) AS EMPLOYEE,
        TRY_CAST(PAYMENTMETHOD AS INT) AS PAYMENTMETHOD,
        TRY_CAST(CURRENCY AS INT) AS CURRENCY,
        TRY_CAST(SOURCETRANSACTION AS INT) AS SOURCETRANSACTION,
        AMOUNTUNBILLED AS AMOUNTUNBILLED,
        EXCHANGERATE AS EXCHANGERATE,
        CAST(TRANDATE AS DATE) AS TRANDATE,
        CAST(CREATEDDATE AS DATE) AS CREATEDDATE,
        CAST(STARTDATE AS DATE) AS STARTDATE,
        CAST(ENDDATE AS DATE) AS ENDDATE,
        CAST(CLOSEDATE AS DATE) AS CLOSEDATE,
        CAST(DUEDATE AS DATE) AS DUEDATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        TRIM(BILLINGADDRESS) AS BILLINGADDRESS,
        TRIM(SHIPPINGADDRESS) AS SHIPPINGADDRESS,
        TRIM(EMAIL) AS EMAIL,
        TRIM(MEMO) AS MEMO,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned