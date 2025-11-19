{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}
 
{{ config(
    database = get_target_database(company),
    alias = 'fact_transaction',
    materialized = 'table',
    unique_key = 'TRANSACTIONS_UNIQUE_ID'
) }}
 

with source as (
    SELECT
    -- Identifiers
    CAST(e.RECORDNO AS VARCHAR) AS TRANSACTIONS_UNIQUE_ID,
    CAST(e.BATCHNO AS INT) AS TRANSACTION_ID,
    e.RECORDNO AS TRANSACTION_LINE_ID,
    e.BATCHNO AS TRANSACTION_NUMBER,
    e.BATCHTITLE AS TRANID,
    CAST(e.TR_TYPE AS VARCHAR) AS TRANSACTION_TYPE,
    e.STATE AS STATUS,
    e.BATCHTITLE AS TITLE,
    e.STATE AS STATUS_NAME,  
 
    -- Accounts
    e.ACCOUNTKEY AS ACCOUNT_ID,
    TRUE AS IS_POSTING,
    CAST(COALESCE(acc.ACCOUNTNO,E.ACCOUNTNO) AS VARCHAR) AS ACCOUNT_NUMBER,
    acc.ACCOUNTTYPE AS ACCOUNT_TYPE,
    COALESCE(acc.TITLE,E.ACCOUNTTITLE) AS ACCOUNT_NAME,
    (HASH(e.ACCOUNTKEY, e.LOCATIONKEY,e.DEPARTMENTKEY,e.PROJECTDIMKEY,e.CLASSDIMKEY)) AS DIM_CHART_OF_ACCOUNT_ID,

    e.CLASSDIMKEY AS DIM_CLASS_ID,
    e.PROJECTDIMKEY AS DIM_PROJECT_ID,
    -- Transaction Line
    e.ITEMDIMKEY AS DIM_ITEM_ID,
    e.DEPARTMENTKEY AS DIM_DEPARTMENT_ID,
    --CAST(NULL AS INT) AS DIM_ENTITY_ID,
    NULL AS TRANSACTION_LINE_TYPE,
    CAST(NULL AS VARCHAR) AS ACCOUNTING_LINE_TYPE,
    e.LOCATIONKEY AS DIM_LOCATION_ID,
    e.VENDORDIMKEY AS DIM_ENTITY_ID,
    e.LOCATIONKEY AS DIM_SUBSIDIARY_ID,
    CAST(NULL AS NUMBER) AS DIM_ADDBACK_ID,
 
    -- Period / Currency
    NULL AS DIM_PERIOD_ID,
    e.BATCH_DATE AS POSTING_PERIOD_DATE,
    e.CURRENCY AS CURRENCY,
    CONCAT(e.LOCATIONKEY, '-', b.BATCH_DATE, '-', e.CURRENCY) AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
    CAST(NULL AS FLOAT) AS EXCHANGERATE,
 
    -- Amounts
    e.TRX_AMOUNT AS NETAMOUNT,
    e.TR_TYPE * e.AMOUNT AS AMOUNT,
    e.TR_TYPE * e.AMOUNT AS AMOUNT_UNCONVERTED,
    e.TRX_AMOUNT AS CONVERTED_NET_AMOUNT,
    CAST(NULL AS FLOAT) AS BOM_QUANTITY,
    CAST(NULL AS FLOAT) AS QUANTITY,
 
    -- Employee / Customer / Address
    CAST(NULL AS INT) AS EMPLOYEE,
    NULL AS BILLINGADDRESS,
    NULL AS SHIPPINGADDRESS,
    NULL AS BILLINGSTATUS,
    b.BATCH_TITLE AS MEMO,
   
    -- Dates
    e.ENTRY_DATE AS TRANDATE,
    CAST(NULL AS DATE) AS STARTDATE,
    TRUNC(e.BATCH_DATE, 'MONTH') AS PERIOD_START_DATE,
    CAST(NULL AS DATE) AS ENDDATE,
    CAST(NULL AS DATE) AS DUEDATE,
    CAST(NULL AS DATE) AS CLOSEDATE,
    e.WHENMODIFIED AS LASTMODIFIEDDATE
 
FROM {{ get_silver_source(company, 'GL_ENTRY') }}  e

LEFT JOIN {{ get_silver_source(company, 'GL_BATCH') }}  b
    ON e.batchno = b.recordno
LEFT JOIN {{ get_silver_source(company, 'GL_ACCOUNT') }} acc
    ON e.ACCOUNTKEY  = acc.RECORDNO
    

 {% if company == 'spotless' %}
    WHERE e.BATCHTITLE not in ('VIE Depreciation & Amortization','record VIE transactions')
    AND LOCATIONKEY <> 492
{% endif %})
SELECT * FROM source
{% if company | lower  == 'amh' %}
    WHERE TRANSACTION_LINE_ID NOT IN 
        (select distinct GLENTRYKEY 
        from {{ get_silver_source(company, 'GL_DETAIL') }}
        WHERE SYMBOL = 'QB_HISTORY' and 
            batch_date between '2022-01-01' and '2022-08-31')
{% else%}
    WHERE 1=1
{% endif %}