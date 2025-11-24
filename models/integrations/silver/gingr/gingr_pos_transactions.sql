{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = (var('company') | lower) == 'wagway'
        and (var('sourcesystem') | lower) == 'gingr'
) }}

{{ config(
    database = get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID','SOURCE_DB']
) }}

with raw as 
(
    select *
    from {{ get_raw_source(company, sourcesystem, 'POS_TRANSACTIONS') }}

    {% if is_incremental() %}
        where ODS_LAST_UPDATE_DATE > (
            select dateadd(
                day,
                -1,
                coalesce(max(t.ODS_LAST_UPDATE_DATE), '1900-01-01'::timestamp_ntz)
            )
            from {{ this }} t
        )
    {% endif %}
),

cleaned as 
(
    select
        CAST(TRIM(ID) AS BIGINT) AS ID,
        TRIM(SOURCE_DB) AS SOURCE_DB,
        CAST(TRIM(OWNER_ID) AS BIGINT) AS OWNER_ID,
        CAST(TRIM(PAYMENT_METHOD_ID) AS BIGINT) AS PAYMENT_METHOD_ID,
        CAST(TRIM(SUBTOTAL) AS BIGINT) AS SUBTOTAL,
        CAST(TRIM(TAX_AMOUNT) AS BIGINT) AS TAX_AMOUNT,
        CAST(TRIM(TOTAL) AS FLOAT) AS TOTAL,
        CAST(TRIM(DISCOUNTS_TOTAL) AS FLOAT) AS DISCOUNTS_TOTAL,
        CAST(TRIM(PAYMENT_AMOUNT) AS FLOAT) AS PAYMENT_AMOUNT,
        CAST(TRIM(CREATE_STAMP) AS BIGINT) AS CREATE_STAMP,
        CAST(TRIM(USER_ID) AS BIGINT) AS USER_ID,
        CAST(TRIM(COMPLETE) AS BOOLEAN) AS COMPLETE,
        CAST(TRIM(LOCATION_ID) AS BIGINT) AS LOCATION_ID,
        TRIM(SALES_TAX_RATE) AS SALES_TAX_RATE,
        CAST(TRIM(STATUS) AS BOOLEAN) AS STATUS,
        CAST(TRIM(OPEN_BALANCE) AS FLOAT) AS OPEN_BALANCE,
        CAST(TRIM(CREDIT_BALANCE) AS FLOAT) AS CREDIT_BALANCE,
        TRIM(MD5_HASH) AS MD5_HASH,
        TRIM(DELETE_INDICATOR) AS DELETE_INDICATOR,
        CAST(TRIM(_FIVETRAN_DELETED) AS BOOLEAN) AS _FIVETRAN_DELETED,
        CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
        CAST(TRIM(ODS_LAST_UPDATE_DATE) AS TIMESTAMP_NTZ) AS ODS_LAST_UPDATE_DATE,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned