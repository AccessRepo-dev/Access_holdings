{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'UNIQUEKEY'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'TRANSACTIONLINE') }}
    {% if is_incremental() %}
    where CAST(LINELASTMODIFIEDDATE AS TIMESTAMP_NTZ) > (
        select coalesce(max(LINELASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        CAST(UNIQUEKEY AS STRING) AS UNIQUEKEY,
        CAST(ID AS INT) AS ID,
        CAST(TRANSACTION AS INT) AS TRANSACTION,
        TRIM(TRANSACTIONLINETYPE) AS TRANSACTIONLINETYPE,
        CAST(ACTUALSHIPDATE AS DATE) AS ACTUALSHIPDATE,
        CAST(BILLEDDATE AS DATE) AS BILLEDDATE,
        CAST(CLOSEDATE AS DATE) AS CLOSEDATE,
        CAST(LINELASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LINELASTMODIFIEDDATE,
        CAST(CREATEDFROM AS INT) AS CREATEDFROM,
        CAST(ORDERPRIORITY AS INT) AS ORDERPRIORITY,
        CAST(ENTITY AS INT) AS ENTITY,
        CAST(CLASS AS INT) AS CLASS,
        CAST(DEPARTMENT AS INT) AS DEPARTMENT,
        {% if company == 'wagway' and sourcesystem == 'netsuite' %}
            CSEG_CP_STORE_LOC AS LOCATION,
        {% else %}
            LOCATION,
        {% endif %}
        CAST(SUBSIDIARY AS INT) AS SUBSIDIARY,
        CAST(ITEM AS INT) AS ITEM,
        TRIM(ITEMTYPE) AS ITEMTYPE,
        CAST(UNITS AS INT) AS UNITS,
        CAST(PRICE AS INT) AS PRICE,

        FOREIGNAMOUNT AS FOREIGNAMOUNT,
        NETAMOUNT AS NETAMOUNT,
        QUANTITY AS QUANTITY,
        RATE AS RATE,

        CAST(PAYMENTMETHOD AS INT) AS PAYMENTMETHOD,
        CAST(
            CASE WHEN ISBILLABLE = 'T' THEN TRUE
                 WHEN ISBILLABLE = 'F' THEN FALSE
                 ELSE NULL END AS BOOLEAN
        ) AS ISBILLABLE,
        CAST(
            CASE WHEN ISCLOSED = 'T' THEN TRUE
                 WHEN ISCLOSED = 'F' THEN FALSE
                 ELSE NULL END AS BOOLEAN
        ) AS ISCLOSED,
        CAST(
            CASE WHEN ISCOGS = 'T' THEN TRUE
                 WHEN ISCOGS = 'F' THEN FALSE
                 ELSE NULL END AS BOOLEAN
        ) AS ISCOGS,
        CAST(
            CASE WHEN ISFULLYSHIPPED = 'T' THEN TRUE
                 WHEN ISFULLYSHIPPED = 'F' THEN FALSE
                 ELSE NULL END AS BOOLEAN
        ) AS ISFULLYSHIPPED,
        TRIM(ACCOUNTINGLINETYPE) AS ACCOUNTINGLINETYPE,
        TRIM(MEMO) AS MEMO,
        TAXLINE AS TAXLINE,
        TRANSACTIONDISCOUNT AS TRANSACTIONDISCOUNT,
        CAST(LINESEQUENCENUMBER AS INT) AS LINESEQUENCENUMBER,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned