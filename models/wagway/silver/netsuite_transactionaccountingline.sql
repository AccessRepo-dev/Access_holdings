{{ config(
    materialized = 'incremental',
    unique_key = ['TRANSACTION_ID', 'TRANSACTION_LINE_ID'],
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(account AS INT) AS ACCOUNT_ID,
    CAST(accountingbook AS INT) AS ACCOUNTING_BOOK_ID,
    accounttype AS ACCOUNT_TYPE,
    CAST(amount AS FLOAT) AS AMOUNT,
    CAST(amountpaid AS FLOAT) AS AMOUNT_PAID,
    CAST(amountunpaid AS FLOAT) AS AMOUNT_UN_PAID,
    CAST(exchangerate AS FLOAT) AS EXCHANGE_RATE,
    CAST(lastmodifieddate AS DATE) AS LAST_MODIFIED_DATE,
    CAST(netamount AS FLOAT) AS NET_AMOUNT,
    posting AS TRANSACTION_ACCOUNTING_POSTING_FLAG,
    CAST(transaction AS INT) AS TRANSACTION_ID,
    CAST(transactionline AS INT) AS TRANSACTION_LINE_ID,
    CURRENT_TIMESTAMP()::TIMESTAMP AS SILVER_LOAD_DATE
FROM {{ source('wagway_netsuite', 'TRANSACTIONACCOUNTINGLINE') }}