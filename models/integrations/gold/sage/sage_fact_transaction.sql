
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    unique_key = 'TRANSACTIONS_UNIQUE_ID'
) }}

with source as (
    SELECT 
    -- Identifiers
    CONCAT(CAST(d.RECORDNO AS VARCHAR), '-', CAST(e.RECORDNO AS VARCHAR)) AS TRANSACTIONS_UNIQUE_ID,
    d.BATCHKEY AS TRANSACTION_ID,
    e.RECORDNO AS TRANSACTION_LINE_ID,
    e.BATCHNO AS TRANSACTION_NUMBER,
    e.BATCHTITLE AS TRANID,
    e.TR_TYPE AS TRANSACTION_TYPE,
    e.STATE AS STATUS,
    e.BATCHTITLE AS TITLE,
    e.STATE AS STATUS_NAME,   

    -- Accounts
    e.ACCOUNTKEY AS ACCOUNT_ID,
    acc.ACCOUNTNO AS ACCOUNT_NUMBER,
    acc.ACCOUNTTYPE AS ACCOUNT_TYPE,
    acc.TITLE AS ACCOUNT_NAME,
    e.ACCOUNTKEY AS DIM_CHART_OF_ACCOUNT_ID,
    e.CLASSID AS DIM_CLASS_ID,

    -- Transaction Line
    e.ITEMDIMKEY AS DIM_ITEM_ID,
    e.CLASSID AS CLASS ,
    e.DEPARTMENTKEY AS DIM_DEPARTMENT_ID,
    NULL AS DIM_ENTITY_ID,
    --NULL AS ITEM_TYPE,
    NULL AS TRANSACTION_LINE_TYPE,
    d.LINE_NO AS ACCOUNTING_LINE_TYPE,
    e.LOCATIONKEY AS DIM_LOCATION_ID,
    e.LOCATIONKEY AS DIM_SUBSIDIARY_ID,
    TRUE AS IS_POSTING,

    -- Period / Currency
    b.BATCH_DATE AS POSTINGPERIOD,
    e.BATCH_DATE AS POSTING_PERIOD_DATE,
    e.CURRENCY AS CURRENCY,
    CONCAT(e.LOCATIONKEY, '-', b.BATCH_DATE, '-', e.CURRENCY) AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
    NULL AS EXCHANGERATE,

    -- Amounts
    e.TRX_AMOUNT AS NETAMOUNT,
    e.AMOUNT AS AMOUNT,
    e.TRX_AMOUNT AS CONVERTED_NET_AMOUNT,
    NULL AS BOM_QUANTITY,
    NULL AS QUANTITY,

    -- Employee / Customer / Address
    NULL AS EMPLOYEE,
    NULL AS BILLINGADDRESS,
    NULL AS SHIPPINGADDRESS,
    NULL AS BILLINGSTATUS,
    b.BATCH_TITLE AS MEMO,

    -- Dates
    e.ENTRY_DATE AS TRANDATE,
    NULL AS STARTDATE,
    NULL AS ENDDATE,
    NULL AS DUEDATE,
    NULL AS CLOSEDATE,
    e.WHENMODIFIED AS LASTMODIFIEDDATE

FROM {{ get_silver_source(company, 'sage_gl_entry') }}  e 
LEFT JOIN {{ get_silver_source(company, 'sage_gl_detail') }} d 
    ON d.GLENTRYKEY = e.recordno
LEFT JOIN {{ get_silver_source(company, 'sage_gl_batch') }}  b 
    ON d.batchkey = b.recordno 
LEFT JOIN {{ get_silver_source(company, 'sage_gl_account') }} acc 
    ON e.ACCOUNTKEY  = acc.RECORDNO 

)
SELECT *
FROM source