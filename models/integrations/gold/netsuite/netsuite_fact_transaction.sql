{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'fact_transaction_new'
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
        HASH(tal.ACCOUNT, tl.SUBSIDIARY) AS DIM_CHART_OF_ACCOUNT_ID,
        tl.CLASS AS DIM_CLASS_ID,
        CAST(NULL AS INT) AS DIM_PROJECT_ID,
        
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
        CAST(t.CURRENCY AS VARCHAR ) AS CURRENCY,
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
        DATE(per.STARTDATE) AS PERIOD_START_DATE , 
        t.ENDDATE,
        t.DUEDATE,
        t.CLOSEDATE,
        t.LASTMODIFIEDDATE
        
    FROM {{ get_silver_source(company, 'TRANSACTIONLINE') }} tl
    LEFT JOIN {{ get_silver_source(company, 'TRANSACTION') }} t
        ON t.ID = tl.TRANSACTION
    LEFT JOIN {{ get_silver_source(company, 'TRANSACTIONACCOUNTINGLINE') }} tal
        ON tl.transaction = tal.transaction and tl.id = tal.transactionline
    LEFT JOIN {{ get_silver_source(company, 'ACCOUNT') }} a
        ON a.ID = tal.ACCOUNT
    LEFT JOIN {{ get_silver_source(company, 'ACCOUNTINGPERIOD') }} per
        ON per.ID = t.POSTINGPERIOD
    LEFT JOIN {{ get_silver_source(company, 'TRANSACTIONSTATUS') }} txs
        ON txs.ID = t.status and txs.trantype = t.type and t.customtype = txs.trancustomtype
 
)

SELECT * FROM source