{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}
 
{{ config(
    database = get_target_database(company),
    alias = 'fact_transaction',
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
    'Net Income',
    'Adjusted EBITDA',
    'Adjustments',
    'Total Liabilities & Equity',
    'Equity',
    'Total Assets',
    'Total Liabilities'
] %}

with source as (
    SELECT
    -- Identifiers
    CAST(e.RECORDNO AS VARCHAR) AS TRANSACTIONS_UNIQUE_ID,
    e.BATCHNO AS TRANSACTION_ID,
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
    e.ACCOUNTKEY AS DIM_CHART_OF_ACCOUNT_ID,
    e.CLASSDIMKEY AS DIM_CLASS_ID,
    {% if company == 'spotless'  %}
        CAST(NULL AS INT) AS DIM_PROJECT_ID,
    {% else %}
        e.PROJECTDIMKEY AS DIM_PROJECT_ID,
    {% endif%}
    map.METRIC_L1,
    map.METRIC_L2,
    map.METRIC_L3,
    CAST(map.METRIC_L4 AS VARCHAR) AS METRIC_L4,
    CAST(map.METRIC_L5 AS VARCHAR) AS METRIC_L5,
    CAST(map.METRIC_L6 AS VARCHAR) AS METRIC_L6,    
    
    -- Transaction Line
    e.ITEMDIMKEY AS DIM_ITEM_ID,
    e.DEPARTMENTKEY AS DIM_DEPARTMENT_ID,
    CAST(NULL AS INT) AS DIM_ENTITY_ID,
    NULL AS TRANSACTION_LINE_TYPE,
    CAST(NULL AS VARCHAR) AS ACCOUNTING_LINE_TYPE,
    e.LOCATIONKEY AS DIM_LOCATION_ID,
    e.LOCATIONKEY AS DIM_SUBSIDIARY_ID,
    CAST(NULL AS NUMBER) AS DIM_ADDBACK_ID,
 
    -- Period / Currency
    per.RECORDNO AS DIM_PERIOD_ID,
    e.BATCH_DATE AS POSTING_PERIOD_DATE,
    e.CURRENCY AS CURRENCY,
    CONCAT(e.LOCATIONKEY, '-', b.BATCH_DATE, '-', e.CURRENCY) AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
    CAST(NULL AS INT) AS EXCHANGERATE,
 
    -- Amounts
    e.TRX_AMOUNT AS NETAMOUNT,
    e.TR_TYPE * e.AMOUNT AS AMOUNT,
    e.TRX_AMOUNT AS CONVERTED_NET_AMOUNT,
    CAST(NULL AS NUMBER(38, 2)) AS BOM_QUANTITY,
    CAST(NULL AS NUMBER(38, 2)) AS QUANTITY,
 
    -- Employee / Customer / Address
    CAST(NULL AS INT) AS EMPLOYEE,
    NULL AS BILLINGADDRESS,
    NULL AS SHIPPINGADDRESS,
    NULL AS BILLINGSTATUS,
    b.BATCH_TITLE AS MEMO,
   
    -- Dates
    e.ENTRY_DATE AS TRANDATE,
    CAST(NULL AS DATE) AS STARTDATE,
    per.START_DATE AS PERIOD_START_DATE,
    CAST(NULL AS DATE) AS ENDDATE,
    CAST(NULL AS DATE) AS DUEDATE,
    CAST(NULL AS DATE) AS CLOSEDATE,
    e.WHENMODIFIED AS LASTMODIFIEDDATE
 
FROM {{ get_silver_source(company, 'GL_ENTRY') }}  e

LEFT JOIN {{ get_silver_source(company, 'GL_BATCH') }}  b
    ON e.batchno = b.recordno
LEFT JOIN {{ get_silver_source(company, 'GL_ACCOUNT') }} acc
    ON e.ACCOUNTKEY  = acc.RECORDNO
LEFT JOIN {{ get_silver_source(company, company ~ '_COA_MAPPING') }} map
    ON 
      {% if company == 'spotless'  %}
            ABS(HASH(e.ACCOUNTKEY, e.LOCATIONKEY)) = ABS(HASH(map.ACCOUNT_ID, map.LOCATION_ID))
        {% else %}
            e.ACCOUNTKEY  = map.ACCOUNT_ID  AND  
            COALESCE(e.LOCATIONKEY ,0)  = COALESCE(map.LOCATION_ID,0)  AND 
            COALESCE(e.DEPARTMENTKEY ,0 )= COALESCE(map.DEPARTMENT_ID ,0) AND 
            COALESCE(e.PROJECTDIMKEY ,0)= COALESCE(map.PROJECT_ID ,0)
        {% endif%}
    
LEFT JOIN {{ get_silver_source(company, 'REPORTING_PERIOD') }} per
    ON TRUNC(e.BATCH_DATE, 'MONTH') = per.START_DATE
),

-- Create derived metric rows
derived_metric_rows as (
    {% for metric in derived_metrics %}
    SELECT
        CAST({{ -loop.index }} AS VARCHAR) AS TRANSACTIONS_UNIQUE_ID,
        NULL AS TRANSACTION_ID,
        NULL AS TRANSACTION_LINE_ID,
        NULL AS TRANSACTION_NUMBER,
        NULL AS TRANID,
        NULL AS TRANSACTION_TYPE,
        NULL AS STATUS,
        NULL AS TITLE,
        NULL AS STATUS_NAME,
        NULL AS ACCOUNT_ID,
        NULL AS IS_POSTING,
        NULL AS ACCOUNT_NUMBER,
        NULL AS ACCOUNT_TYPE,
        NULL AS ACCOUNT_NAME,
        NULL AS DIM_CHART_OF_ACCOUNT_ID,
        NULL AS DIM_CLASS_ID,
        NULL AS DIM_PROJECT_ID,
        '{{ metric }}' AS METRIC_L1,
        CASE WHEN '{{ metric }}' = 'Equity' THEN 'Net Income' ELSE NULL END AS METRIC_L2,
        NULL AS METRIC_L3,
        NULL AS METRIC_L4,
        NULL AS METRIC_L5,
        NULL AS METRIC_L6,
        NULL AS DIM_ITEM_ID,
        NULL AS DIM_DEPARTMENT_ID,
        NULL AS DIM_ENTITY_ID,
        NULL AS TRANSACTION_LINE_TYPE,
        NULL AS ACCOUNTING_LINE_TYPE,
        NULL AS DIM_LOCATION_ID,
        NULL AS DIM_SUBSIDIARY_ID,
        NULL AS DIM_ADDBACK_ID,
        NULL AS DIM_PERIOD_ID,
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
        NULL AS PERIOD_START_DATE,
        NULL AS ENDDATE,
        NULL AS DUEDATE,
        NULL AS CLOSEDATE,
        NULL AS LASTMODIFIEDDATE
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
),

-- Final union of actual data and derived metrics
final_result as (
    SELECT * FROM source
    UNION ALL
    SELECT * FROM derived_metric_rows
)

SELECT * FROM final_result