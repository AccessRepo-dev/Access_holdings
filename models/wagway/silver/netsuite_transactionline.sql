{{ config(
    materialized = 'incremental',
    unique_key = 'UNIQUE_KEY',
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(uniquekey AS STRING) AS UNIQUE_KEY,
    CAST(id AS INT) AS TRANSACTION_LINE_ID,
    CAST(transaction AS INT) AS TRANSACTION_ID,
    transactionlinetype AS TRANSACTION_LINE_TYPE,
    CAST(actualshipdate AS DATE) AS ACTUAL_SHIP_DATE,
    CAST(billeddate AS DATE) AS BILLED_DATE,
    CAST(closedate AS DATE) AS CLOSE_DATE,
    CAST(linelastmodifieddate AS DATE) AS LINE_LAST_MODIFIED_DATE,
    CAST(createdfrom AS INT) AS CREATED_FROM_TRANSACTION_ID,
    CAST(orderpriority AS INT) AS ORDER_PRIORITY,
    CAST(entity AS INT) AS ENTITY_ID,
    CAST(class AS INT) AS CLASS_ID,
    CAST(department AS INT) AS DEPARTMENT_ID,
    CAST(location AS INT) AS LOCATION_ID,
    CAST(subsidiary AS INT) AS SUBSIDIARY_ID,
    CAST(item AS INT) AS ITEM_ID,
    itemtype AS ITEM_TYPE,
    CAST(units AS INT) AS UNITS_ID,
    CAST(price AS INT) AS PRICE_ID,
    CAST(foreignamount AS FLOAT) AS FOREIGN_AMOUNT,
    CAST(netamount AS FLOAT) AS NET_AMOUNT,
    CAST(quantity AS FLOAT) AS QUANTITY,
    CAST(rate AS FLOAT) AS RATE,
    CAST(paymentmethod AS INT) AS PAYMENT_METHOD_ID,
    CAST(
        CASE WHEN isbillable = 'T' THEN TRUE
             WHEN isbillable = 'F' THEN FALSE
             ELSE NULL END AS BOOLEAN
    ) AS IS_BILLABLE,
    CAST(
        CASE WHEN isclosed = 'T' THEN TRUE
             WHEN isclosed = 'F' THEN FALSE
             ELSE NULL END AS BOOLEAN
    ) AS IS_CLOSED,
    CAST(
        CASE WHEN iscogs = 'T' THEN TRUE
             WHEN iscogs = 'F' THEN FALSE
             ELSE NULL END AS BOOLEAN
    ) AS IS_COGS,
    CAST(
        CASE WHEN isfullyshipped = 'T' THEN TRUE
             WHEN isfullyshipped = 'F' THEN FALSE
             ELSE NULL END AS BOOLEAN
    ) AS IS_FULLY_SHIPPED,
    TRIM(accountinglinetype) AS ACCOUNTING_LINE_TYPE,
    TRIM(memo) AS MEMO,
    taxline AS TAX_LINE,
    transactiondiscount AS TRANSACTION_DISCOUNT,
    CAST(linesequencenumber AS INT) AS LINE_SEQUENCE_NUMBER_ID,
    _FIVETRAN_DELETED AS IS_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM {{ source('wagway_netsuite', 'TRANSACTIONLINE') }}

{% if is_incremental() %}
WHERE CAST(LINELASTMODIFIEDDATE AS TIMESTAMP_NTZ) > (
    SELECT COALESCE(MAX(LINE_LAST_MODIFIED_DATE), '1900-01-01'::TIMESTAMP_NTZ)
    FROM {{ this }}
)
{% endif %}
