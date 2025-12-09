{% set company = var('company','wagway') %}
{% set sourcesystem = var('sourcesystem','gingr') %}

{{ config(enabled =  (var('sourcesystem','gingr')| lower) == 'gingr') }}

{{ config(
    database = get_target_database(var('company','wagway')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID', 'SOURCE_DB']
) }}

with raw as 
(
    select *
    from {{ get_raw_source(company, sourcesystem, 'POS_TRANSACTION_ITEMS_AUDIT') }}

    {% if is_incremental() %}
        where ODS_LAST_UPDATE_DATE > (
            select dateadd(
                day,
                -1,
                coalesce(max(t.ODS_LAST_UPDATE_DATE), '1900-01-01'::timestamp_ntz)
            )
            from {{ this }} t
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as 
(
    select
        CAST(ID AS BIGINT) AS ID,
        TRIM(SOURCE_DB) AS SOURCE_DB,
        CAST(POS_TRANSACTION_ID AS BIGINT) AS POS_TRANSACTION_ID,
        TRIM(ITEM_ID) AS ITEM_ID,
        TRIM(DESCRIPTION) AS DESCRIPTION,
        CAST(TRIM(PRICE) AS FLOAT) AS PRICE,
        CAST(TRIM(DISCOUNTS_TOTAL) AS FLOAT) AS DISCOUNTS_TOTAL,
        CAST(TRIM(TAX_AMOUNT) AS FLOAT) AS TAX_AMOUNT,
        CAST(TRIM(IS_RETURNED) AS BOOLEAN) AS IS_RETURNED,
        CAST(TRIM(REFUND_AMOUNT) AS FLOAT) AS REFUND_AMOUNT,
        CAST(TRIM(TAX_REFUND_AMOUNT) AS FLOAT) AS TAX_REFUND_AMOUNT,
        CAST(TRIM(RETURNED_TO_INVENTORY) AS BOOLEAN) AS RETURNED_TO_INVENTORY,
        CAST(TRIM(RETURN_REASON) AS BIGINT) AS RETURN_REASON,
        CAST(TRIM(RETURNED_AT) AS TIMESTAMP_NTZ) AS RETURNED_AT,
        CAST(RETURN_TRANSACTION_ID AS BIGINT) AS RETURN_TRANSACTION_ID,
        CAST(CATEGORY_ID AS BIGINT) AS CATEGORY_ID,
        CAST(ITEM_BASE_ID AS BIGINT) AS ITEM_BASE_ID,
        CAST(TYPE_ID AS BIGINT) AS TYPE_ID,
        CAST(ACCOUNT_CODE_ID AS INT) AS ACCOUNT_CODE_ID,
        CAST(TRIM(TIMESTAMP) AS TIMESTAMP_NTZ) AS TIMESTAMP,
        TRIM(WHY) AS WHY,
        TRIM(DELETE_INDICATOR) AS DELETE_INDICATOR,
        CAST(TRIM(_FIVETRAN_DELETED) AS BOOLEAN) AS _FIVETRAN_DELETED,
        CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
        CAST(TRIM(ODS_LAST_UPDATE_DATE) AS TIMESTAMP_NTZ) AS ODS_LAST_UPDATE_DATE,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
