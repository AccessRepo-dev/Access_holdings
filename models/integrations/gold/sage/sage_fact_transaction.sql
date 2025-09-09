
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    unique_key = 'TRANSACTION_LINE_ID'
) }}

with source as (
    SELECT 
    e.RECORDNO AS TRANSACTION_LINE_ID,
    d.RECORDNO AS TRANSACTIONS_UNIQUE_ID,
    b.RECORDNO AS TRAN_ID,

    d.BATCHKEY AS TRANSACTION_ID,
    e.BATCHNO AS TRANSACTION_NUMBER,
    e.LINE_NO AS TRANSACTION_LINE_NO,
    d.LINE_NO AS ACCOUNTING_LINE_NO,

    e.TR_TYPE AS TRANSACTION_TYPE,
    e.BATCHTITLE AS TITLE,
    b.BATCH_TITLE AS MEMO,
    e.STATE AS STATE,

    e.ENTRY_DATE AS TRAN_DATE,
    b.BATCH_DATE AS REPORTING_PERIOD_ID,
    b.BATCH_DATE AS POSTING_PERIOD_DATE,

    e.ACCOUNTKEY AS ACCOUNT_ID,
    e.CLASSID AS CLASS_ID,
    CONCAT(ACCOUNTKEY,e.CLASSID) AS CHART_OF_ACCOUNTS_UNIQUE_ID,
    e.ITEMID AS ITEM_ID,
    e.CURRENCY AS CURRENCY_ID,
    e.LOCATIONKEY AS LOCATION_ID,
    e.DEPARTMENTKEY AS DEPARTMENT_ID,
    d.LOCATIONID AS SUBSIDIARY_ID,
    d.TRX_AMOUNT AS NET_AMOUNT,
    d.AMOUNT AS AMOUNT,
    b.WHENMODIFIED AS LAST_MODIFIED_DATE
    FROM {{ get_silver_source(company, 'sage_gl_detail') }} d 
    LEFT JOIN {{ get_silver_source(company, 'sage_gl_batch') }}  b on d.batchkey = b.recordno 
    LEFT JOIN {{ get_silver_source(company, 'sage_gl_entry') }}  e on d.GLENTRYKEY = e.recordno

)
SELECT *
FROM source