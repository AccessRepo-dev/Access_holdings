
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
    l.ENTITY AS SUBSIDIARY_ID,

    e.TR_TYPE AS TRANSACTION_TYPE,
    e.BATCHTITLE AS TITLE,
    b.BATCH_TITLE AS MEMO,
    e.STATE AS STATE,

    e.ENTRY_DATE AS TRAN_DATE,
    b.BATCH_DATE AS REPORTING_PERIOD_ID,
    e.BATCH_DATE AS POSTING_PERIOD_DATE,

    e.ACCOUNTKEY AS ACCOUNT_ID,
    e.CLASSID AS CLASS_ID,
    ABS(HASH(e.ACCOUNTKEY,l.ENTITY)) AS CHART_OF_ACCOUNTS_UNIQUE_ID,
    e.ITEMDIMKEY as ITEM_ID,
    e.CURRENCY AS CURRENCY_ID,
    e.LOCATIONKEY AS LOCATION_ID,
    e.LOCATIONNAME AS LOCATION_NAME,
    e.DEPARTMENTKEY AS DEPARTMENT_ID,
 
    e.TRX_AMOUNT AS NET_AMOUNT,
    e.AMOUNT AS AMOUNT,
    e.WHENMODIFIED AS LAST_MODIFIED_DATE
    FROM {{ get_silver_source(company, 'sage_gl_entry') }}  e 
    LEFT JOIN  {{ get_silver_source(company, 'sage_gl_detail') }} d on d.GLENTRYKEY = e.recordno
    LEFT JOIN {{ get_silver_source(company, 'sage_gl_batch') }}  b on d.batchkey = b.recordno 
    LEFT JOIN {{ get_silver_source(company, 'sage_location') }}  l on l.RECORDNO = e.LOCATIONKEY 
)
SELECT *
FROM source