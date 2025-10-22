{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'fact_transaction_trimmed'
) }}

with source as (
    SELECT 
        -- Unique identifiers
        CONCAT(
            COALESCE(CAST(tl.TRANSACTION AS VARCHAR), '0'), '-', 
            COALESCE(CAST(tl.ID AS VARCHAR), '0')
        ) AS TRANSACTIONS_UNIQUE_ID,
        tl.TRANSACTION AS TRANSACTION_ID,
        tl.ID AS TRANSACTION_LINE_ID,
        t.TRANSACTIONNUMBER AS TRANSACTION_NUMBER,
        t.TRANID,
        t.TYPE AS TRANSACTION_TYPE,
        t.STATUS,
        t.TITLE,
        txs.NAME AS STATUS_NAME,
        
        -- Chart of accounts / account details
        tal.ACCOUNT AS ACCOUNT_ID,
        tal.POSTING AS IS_POSTING,
        a.ACCTNUMBER AS ACCOUNT_NUMBER,
        a.ACCTTYPE AS ACCOUNT_TYPE,
        a.FULLNAME AS ACCOUNT_NAME,
        HASH(tal.ACCOUNT, tl.SUBSIDIARY, tl.CLASS, tl.LOCATION, tl.DEPARTMENT) AS DIM_CHART_OF_ACCOUNT_ID,
        tl.CLASS AS DIM_CLASS_ID,
        CAST(NULL AS NUMBER) AS DIM_PROJECT_ID,
        
        -- Transaction line details
        tl.ITEM AS DIM_ITEM_ID,
        tl.DEPARTMENT AS DIM_DEPARTMENT_ID,
        tl.ENTITY AS DIM_ENTITY_ID,
        tl.TRANSACTIONLINETYPE AS TRANSACTION_LINE_TYPE,
        tl.ACCOUNTINGLINETYPE AS ACCOUNTING_LINE_TYPE,
        tl.LOCATION AS DIM_LOCATION_ID,
        tl.SUBSIDIARY AS DIM_SUBSIDIARY_ID,
        
        {% if company == 'wagway' %}
            tl.ADDBACK_ID AS DIM_ADDBACK_ID,
        {% else %}
            CAST(NULL AS NUMBER) AS DIM_ADDBACK_ID,
        {% endif %}
        
        -- Period / currency / consolidation
        t.POSTINGPERIOD AS DIM_PERIOD_ID,
        per.CLOSEDONDATE AS POSTING_PERIOD_DATE,
        CAST(t.CURRENCY AS VARCHAR) AS CURRENCY,
        CONCAT(tl.SUBSIDIARY, '-', t.POSTINGPERIOD, '-', t.CURRENCY) AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        t.EXCHANGERATE,
        
        -- Amounts
        tal.NETAMOUNT,
        tal.AMOUNT,
        ROUND(tal.NETAMOUNT * t.EXCHANGERATE, 2) AS CONVERTED_NET_AMOUNT,
        ROUND(tal.NETAMOUNT * CAST(tl.QUANTITY AS NUMBER), 2) AS BOM_QUANTITY,
        tl.QUANTITY,
        
        -- Employee / address / customer side
        t.EMPLOYEE,
        t.BILLINGADDRESS,
        t.SHIPPINGADDRESS,
        t.BILLINGSTATUS,
        t.MEMO,
        
        -- Dates
        t.TRANDATE,
        t.STARTDATE,
        DATE(per.STARTDATE) AS PERIOD_START_DATE,
        t.ENDDATE,
        t.DUEDATE,
        t.CLOSEDATE,
        t.LASTMODIFIEDDATE
        
    FROM {{ get_silver_source(company, 'TRANSACTIONLINE') }} tl
    LEFT JOIN {{ get_silver_source(company, 'TRANSACTION') }} t
        ON t.ID = tl.TRANSACTION
    LEFT JOIN {{ get_silver_source(company, 'TRANSACTIONACCOUNTINGLINE') }} tal
        ON tl.transaction = tal.transaction AND tl.id = tal.transactionline
    LEFT JOIN {{ get_silver_source(company, 'ACCOUNT') }} a
        ON a.ID = tal.ACCOUNT
    LEFT JOIN {{ get_silver_source(company, 'ACCOUNTINGPERIOD') }} per
        ON per.ID = t.POSTINGPERIOD
    LEFT JOIN {{ get_silver_source(company, 'TRANSACTIONSTATUS') }} txs
        ON txs.ID = t.status AND txs.trantype = t.type AND t.customtype = txs.trancustomtype
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
            COALESCE(CAST(DIM_SUBSIDIARY_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_DEPARTMENT_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_LOCATION_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_CLASS_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_ITEM_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_PROJECT_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_ADDBACK_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_CHART_OF_ACCOUNT_ID AS VARCHAR), '0'), '-',
            COALESCE(CAST(DIM_PERIOD_ID AS VARCHAR), '0')
        ) AS TRANSACTIONS_UNIQUE_ID,
        
        -- Nullified transaction-level fields (matching order from source)
        CAST(NULL AS NUMBER) AS TRANSACTION_ID,
        CAST(NULL AS NUMBER) AS TRANSACTION_LINE_ID,
        CAST(NULL AS TEXT) AS TRANSACTION_NUMBER,
        CAST(NULL AS TEXT) AS TRANID,
        CAST('AGGREGATED' AS TEXT) AS TRANSACTION_TYPE,
        CAST(NULL AS TEXT) AS STATUS,
        CAST(NULL AS TEXT) AS TITLE,
        CAST(NULL AS TEXT) AS STATUS_NAME,
        
        -- Chart of accounts (keeping aggregation keys)
        CAST(NULL AS NUMBER) AS ACCOUNT_ID,
        CAST(NULL AS BOOLEAN) AS IS_POSTING,
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
        AVG(EXCHANGERATE) AS EXCHANGERATE,
        
        -- Aggregated amounts
        SUM(NETAMOUNT) AS NETAMOUNT,
        SUM(AMOUNT) AS AMOUNT,
        SUM(CONVERTED_NET_AMOUNT) AS CONVERTED_NET_AMOUNT,
        SUM(BOM_QUANTITY) AS BOM_QUANTITY,
        SUM(QUANTITY) AS QUANTITY,
        
        -- Nullified detail fields
        CAST(NULL AS NUMBER) AS EMPLOYEE,
        CAST(NULL AS TEXT) AS BILLINGADDRESS,
        CAST(NULL AS TEXT) AS SHIPPINGADDRESS,
        CAST(NULL AS TEXT) AS BILLINGSTATUS,
        CAST('AGGREGATED HISTORICAL TRANSACTIONS' AS TEXT) AS MEMO,
        
        -- Dates
        MIN(PERIOD_START_DATE) AS TRANDATE,
        MIN(STARTDATE) AS STARTDATE,
        MIN(PERIOD_START_DATE) AS PERIOD_START_DATE,
        MAX(ENDDATE) AS ENDDATE,
        MAX(DUEDATE) AS DUEDATE,
        MAX(CLOSEDATE) AS CLOSEDATE,
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