{{ config(
    materialized = 'incremental',
    unique_key = 'TRANSACTION_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(postingperiod AS INT) AS POSTING_PERIOD_ID,
    CAST(amountunbilled AS FLOAT) AS AMOUNT_UNBILLED,
    billingaddress AS BILLING_ADDRESS_ID,
    CAST(closedate AS DATE) AS CLOSE_DATE,
    status AS TRANSACTION_STATUS_ID,   
    CAST(createddate AS DATE) AS CREATED_DATE,
    CAST(employee AS INT) AS EMPLOYEE_ID,
    CAST(sourcetransaction AS INT) AS SOURCE_TRANSACTION,
    CAST(currency AS INT) AS CURRENCY_ID,
    CAST(lastmodifieddate AS DATE) AS LAST_MODIFIED_DATE,
    CAST(duedate AS DATE) AS DUE_DATE,
    email AS SESSION_SHOP_EMAIL,
    CAST(enddate AS DATE) AS END_DATE,
    CAST(entity AS INT) AS INTERNAL_ENTITY_ID,
    CAST(exchangerate AS FLOAT) AS EXCHANGE_RATE,
    memo AS MEMO,
    CAST(paymentmethod AS INT) AS PAYMENT_METHOD_ID,
    shippingaddress AS SHIPPING_ADDRESS_ID,
    CAST(startdate AS DATE) AS START_DATE,
    billingstatus AS BILLING_STATUS,
    title AS TITLE,
    CAST(trandate AS DATE) AS TRAN_DATE,
    tranid AS TRANS_ID,
    id AS TRANSACTION_ID,
    TRANSACTIONNUMBER AS TRANSACTION_NUMBER,
    source AS SOURCE,
    type AS TRANSACTION_TYPE,
    CURRENT_TIMESTAMP()::TIMESTAMP AS SILVER_LOAD_DATE
FROM {{ source('wagway_netsuite', 'TRANSACTION') }}
