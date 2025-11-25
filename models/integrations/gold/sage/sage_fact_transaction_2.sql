{% set company = var('company', 'Unknown company') | lower %}
--{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}
 
{{ config(
    enabled = false,
    database = get_target_database(company),
    materialized = 'table',
    alias = 'fact_transaction_trimmed'
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
    CAST(NULL AS FLOAT) AS EXCHANGERATE,
 
    -- Amounts
    e.TRX_AMOUNT AS NETAMOUNT,
    e.TR_TYPE * e.AMOUNT AS AMOUNT,
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
    per.START_DATE AS PERIOD_START_DATE,
    CAST(NULL AS DATE) AS ENDDATE,
    CAST(NULL AS DATE) AS DUEDATE,
    CAST(NULL AS DATE) AS CLOSEDATE,
    e.WHENMODIFIED AS LASTMODIFIEDDATE
     
    FROM {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_GL_ENTRY') }} e
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_GL_BATCH') }} b
        ON e.batchno = b.recordno
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_GL_ACCOUNT') }} acc
        ON e.ACCOUNTKEY = acc.RECORDNO
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_REPORTING_PERIOD') }} per
        ON TRUNC(e.BATCH_DATE, 'MONTH') = per.START_DATE

    {% if company == 'spotless' %}
        WHERE e.BATCHTITLE not in ('VIE Depreciation & Amortization','record VIE transactions')
        AND LOCATIONKEY <> 492
    {% endif %}
        
),

-- Transactions within the current year (detailed level)
current_year_transactions as (
    SELECT *
    FROM source
    WHERE PERIOD_START_DATE >= DATE_TRUNC('MONTH', DATEADD('MONTH', -12, CURRENT_DATE))
),

-- Transactions older than a year (aggregated level)
historical_aggregated as (
    SELECT
        -- Generate aggregated unique ID
        CONCAT(
            'AGG-',
            COALESCE(CAST(DIM_SUBSIDIARY_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_DEPARTMENT_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_LOCATION_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_CLASS_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_ITEM_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_PROJECT_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_ADDBACK_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_CHART_OF_ACCOUNT_ID AS TEXT), '0'), '-',
            COALESCE(CAST(DIM_PERIOD_ID AS TEXT), '0')
        ) AS TRANSACTIONS_UNIQUE_ID,
        
        -- Nullified transaction-level fields (matching order from source)
        CAST(NULL AS NUMBER) AS TRANSACTION_ID,
        CAST(NULL AS NUMBER) AS TRANSACTION_LINE_ID,
        CAST(NULL AS NUMBER) AS TRANSACTION_NUMBER,
        CAST(NULL AS TEXT) AS TRANID,
        CAST('AGGREGATED' AS TEXT) AS TRANSACTION_TYPE,
        CAST(NULL AS TEXT) AS STATUS,
        CAST(NULL AS TEXT) AS TITLE,
        CAST(NULL AS TEXT) AS STATUS_NAME,
        
        -- Chart of accounts (keeping aggregation keys)
        CAST(NULL AS NUMBER) AS ACCOUNT_ID,
        CAST(TRUE AS BOOLEAN) AS IS_POSTING,
        ACCOUNT_NUMBER,
        ACCOUNT_TYPE,
        ACCOUNT_NAME,
        DIM_CHART_OF_ACCOUNT_ID,
        DIM_CLASS_ID,
        DIM_PROJECT_ID,
        
        -- Transaction line details (keeping aggregation keys)
        DIM_ITEM_ID,
        DIM_DEPARTMENT_ID,
        CAST(NULL AS NUMBER) AS DIM_ENTITY_ID,
        CAST(NULL AS TEXT) AS TRANSACTION_LINE_TYPE,
        CAST(NULL AS TEXT) AS ACCOUNTING_LINE_TYPE,
        DIM_LOCATION_ID,
        DIM_SUBSIDIARY_ID,
        DIM_ADDBACK_ID,
        
        -- Period / currency / consolidation
        DIM_PERIOD_ID,
        MIN(POSTING_PERIOD_DATE) AS POSTING_PERIOD_DATE,
        CAST(NULL AS TEXT) AS CURRENCY,
        CAST(NULL AS TEXT) AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        CAST(NULL AS FLOAT) AS EXCHANGERATE,
        
        -- Aggregated amounts
        SUM(NETAMOUNT) AS NETAMOUNT,
        SUM(AMOUNT) AS AMOUNT,
        SUM(CONVERTED_NET_AMOUNT) AS CONVERTED_NET_AMOUNT,
        CAST(NULL AS FLOAT) AS BOM_QUANTITY,
        CAST(NULL AS FLOAT) AS QUANTITY,
        
        -- Nullified detail fields
        CAST(NULL AS NUMBER) AS EMPLOYEE,
        CAST(NULL AS TEXT) AS BILLINGADDRESS,
        CAST(NULL AS TEXT) AS SHIPPINGADDRESS,
        CAST(NULL AS TEXT) AS BILLINGSTATUS,
        CAST('AGGREGATED HISTORICAL TRANSACTIONS' AS TEXT) AS MEMO,
        
        -- Dates
        MIN(PERIOD_START_DATE) AS TRANDATE,
        CAST(NULL AS DATE) AS STARTDATE,
        MIN(PERIOD_START_DATE) AS PERIOD_START_DATE,
        CAST(NULL AS DATE) AS ENDDATE,
        CAST(NULL AS DATE) AS DUEDATE,
        CAST(NULL AS DATE) AS CLOSEDATE,
        MAX(LASTMODIFIEDDATE) AS LASTMODIFIEDDATE
        
    FROM source
    WHERE PERIOD_START_DATE < DATE_TRUNC('MONTH', DATEADD('MONTH', -12, CURRENT_DATE))
    
    GROUP BY
        DIM_SUBSIDIARY_ID,
        DIM_DEPARTMENT_ID,
        DIM_LOCATION_ID,
        DIM_CLASS_ID,
        DIM_ITEM_ID,
        DIM_PROJECT_ID,
        DIM_ADDBACK_ID,
        DIM_CHART_OF_ACCOUNT_ID,
        ACCOUNT_NUMBER,
        ACCOUNT_NAME,
        ACCOUNT_TYPE,
        DIM_PERIOD_ID
),

-- Union both datasets
final as (
    SELECT * FROM current_year_transactions
    
    UNION ALL
    
    SELECT * FROM historical_aggregated
)

SELECT * FROM final