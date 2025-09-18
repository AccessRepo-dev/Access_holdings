{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}
 
{{ config(
    database = get_target_database(company),
    materialized = 'table',
    unique_key = 'TRANSACTIONS_UNIQUE_ID'
) }}
 
-- Define derived metrics as a macro variable for reusability
{% set derived_metrics = [
    'Gross Profit',
    'Gross Margin',
    'EBITDA',
    'EBITDA Margin',
    'Field EBITDA',
    'Field EBITDA Margin',
    'Post Corporate EBITDA',
    'Post Corporate EBITDA Margin',
    'Net Income'
] %}

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
    e.ACCOUNTKEY  AS DIM_CHART_OF_ACCOUNT_ID,
    e.CLASSID AS DIM_CLASS_ID,
    map.METRIC_L1,
    map.METRIC_L2,
    map.METRIC_L3,
    map.METRIC_L4,
    map.METRIC_L5,
    map.METRIC_L6,    
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
    e.TR_TYPE * e.TRX_AMOUNT AS NETAMOUNT,
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
LEFT JOIN {{ get_silver_source(company, 'sage_coa_mapping') }} map
    ON ABS(HASH(e.ACCOUNTKEY, e.LOCATIONKEY)) = ABS(HASH(map.ACCOUNT_ID, map.LOCATION_ID))
),

-- Create derived metric rows
derived_metric_rows as (
    {% for metric in derived_metrics %}
    SELECT
        CAST({{ -loop.index }} AS VARCHAR) AS TRANSACTIONS_UNIQUE_ID,  -- Negative integers for uniqueness
        NULL AS TRANSACTION_ID,
        NULL AS TRANSACTION_LINE_ID,
        NULL AS TRANSACTION_NUMBER,
        NULL AS TRANID,
        NULL AS TRANSACTION_TYPE,
        NULL AS STATUS,
        NULL AS TITLE,
        NULL AS STATUS_NAME,
        NULL AS ACCOUNT_ID,
        NULL AS ACCOUNT_NUMBER,
        NULL AS ACCOUNT_TYPE,
        NULL AS ACCOUNT_NAME,
        NULL AS DIM_CHART_OF_ACCOUNT_ID,
        NULL AS DIM_CLASS_ID,
        '{{ metric }}' AS METRIC_L1,  -- Only METRIC_L1 is populated with the derived metric name
        NULL AS METRIC_L2,
        NULL AS METRIC_L3,
        NULL AS METRIC_L4,
        NULL AS METRIC_L5,
        NULL AS METRIC_L6,
        NULL AS DIM_ITEM_ID,
        NULL AS CLASS,
        NULL AS DIM_DEPARTMENT_ID,
        NULL AS DIM_ENTITY_ID,
        NULL AS TRANSACTION_LINE_TYPE,
        NULL AS ACCOUNTING_LINE_TYPE,
        NULL AS DIM_LOCATION_ID,
        NULL AS DIM_SUBSIDIARY_ID,
        NULL AS IS_POSTING,
        NULL AS POSTINGPERIOD,
        NULL AS POSTING_PERIOD_DATE,
        NULL AS CURRENCY,
        NULL AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        NULL AS EXCHANGERATE,
        NULL AS NETAMOUNT,
        NULL AS AMOUNT,
        NULL AS CONVERTED_NET_AMOUNT,
        NULL AS BOM_QUANTITY,
        NULL AS QUANTITY,
        NULL AS EMPLOYEE,
        NULL AS BILLINGADDRESS,
        NULL AS SHIPPINGADDRESS,
        NULL AS BILLINGSTATUS,
        NULL AS MEMO,
        NULL AS TRANDATE,
        NULL AS STARTDATE,
        NULL AS ENDDATE,
        NULL AS DUEDATE,
        NULL AS CLOSEDATE,
        NULL AS LASTMODIFIEDDATE
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}

    UNION ALL

    SELECT
        CAST(-{{ derived_metrics | length + 1 }} AS VARCHAR) AS TRANSACTIONS_UNIQUE_ID,  -- Negative integers for uniqueness
        NULL AS TRANSACTION_ID,
        NULL AS TRANSACTION_LINE_ID,
        NULL AS TRANSACTION_NUMBER,
        NULL AS TRANID,
        NULL AS TRANSACTION_TYPE,
        NULL AS STATUS,
        NULL AS TITLE,
        NULL AS STATUS_NAME,
        NULL AS ACCOUNT_ID,
        NULL AS ACCOUNT_NUMBER,
        NULL AS ACCOUNT_TYPE,
        NULL AS ACCOUNT_NAME,
        NULL AS DIM_CHART_OF_ACCOUNT_ID,
        NULL AS DIM_CLASS_ID,
        'Equity' AS METRIC_L1,
        'Net Income' AS METRIC_L2,
        NULL AS METRIC_L3,
        NULL AS METRIC_L4,
        NULL AS METRIC_L5,
        NULL AS METRIC_L6,
        NULL AS DIM_ITEM_ID,
        NULL AS CLASS,
        NULL AS DIM_DEPARTMENT_ID,
        NULL AS DIM_ENTITY_ID,
        NULL AS TRANSACTION_LINE_TYPE,
        NULL AS ACCOUNTING_LINE_TYPE,
        NULL AS DIM_LOCATION_ID,
        NULL AS DIM_SUBSIDIARY_ID,
        NULL AS IS_POSTING,
        NULL AS POSTINGPERIOD,
        NULL AS POSTING_PERIOD_DATE,
        NULL AS CURRENCY,
        NULL AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        NULL AS EXCHANGERATE,
        NULL AS NETAMOUNT,
        NULL AS AMOUNT,
        NULL AS CONVERTED_NET_AMOUNT,
        NULL AS BOM_QUANTITY,
        NULL AS QUANTITY,
        NULL AS EMPLOYEE,
        NULL AS BILLINGADDRESS,
        NULL AS SHIPPINGADDRESS,
        NULL AS BILLINGSTATUS,
        NULL AS MEMO,
        NULL AS TRANDATE,
        NULL AS STARTDATE,
        NULL AS ENDDATE,
        NULL AS DUEDATE,
        NULL AS CLOSEDATE,
        NULL AS LASTMODIFIEDDATE
),

-- Final union of actual data and derived metrics
final_result as (
    SELECT * FROM source
    UNION ALL
    SELECT * FROM derived_metric_rows
)

SELECT * FROM final_result