{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'fact_transaction'
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
       
         {% if company == 'wagway' %}
             HASH(tal.ACCOUNT, tl.SUBSIDIARY,tl.CLASS,tl.LOCATION,tl.DEPARTMENT,tl.ADDBACK_ID) AS DIM_CHART_OF_ACCOUNT_ID,
        {% else %}
             HASH(tal.ACCOUNT, tl.SUBSIDIARY,tl.CLASS,tl.LOCATION,tl.DEPARTMENT) AS DIM_CHART_OF_ACCOUNT_ID,
        {% endif %}
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
        CAST(sub.CURRENCY AS VARCHAR ) AS CURRENCY,
        CONCAT(tl.SUBSIDIARY, '-', t.POSTINGPERIOD, '-', t.CURRENCY) AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        CASE WHEN sub.CURRENCY=1 OR sub.CURRENCY IS NULL THEN 1 ELSE cer.CURRENTRATE  END AS EXCHANGERATE,
        -- Amounts
        tal.NETAMOUNT,
        tal.AMOUNT AS AMOUNT_UNCONVERTED,
        CASE 
            WHEN coa.IS_BS = 'IS' AND NOT (t.CURRENCY IS NULL or sub.currency=1) THEN ROUND(tal.AMOUNT * cer.AVERAGERATE, 2)
            WHEN coa.METRIC_L1 = 'Equity' AND NOT (t.CURRENCY IS NULL or sub.currency=1) THEN ROUND(tal.AMOUNT * cer.HISTORICALRATE, 2)
            ELSE tal.AMOUNT
        END AS AMOUNT,
        CASE WHEN sub.CURRENCY=1 OR t.CURRENCY IS NULL THEN tal.NETAMOUNT ELSE ROUND(tal.NETAMOUNT * cer.CURRENTRATE, 2) END AS CONVERTED_NET_AMOUNT,
        cer.AVERAGERATE,
        cer.CURRENTRATE,
        cer.HISTORICALRATE,
        CASE WHEN sub.CURRENCY=1 OR t.CURRENCY IS NULL THEN tal.AMOUNT ELSE ROUND(tal.AMOUNT * cer.AVERAGERATE, 2)  END AS AMOUNT_AR,
        CASE WHEN sub.CURRENCY=1 OR t.CURRENCY IS NULL THEN tal.AMOUNT ELSE ROUND(tal.AMOUNT * cer.CURRENTRATE, 2)  END AS AMOUNT_CR,
        CASE WHEN sub.CURRENCY=1 OR t.CURRENCY IS NULL THEN tal.AMOUNT ELSE ROUND(tal.AMOUNT * cer.HISTORICALRATE, 2)  END AS AMOUNT_HR,
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
    LEFT JOIN {{ get_silver_source(company, 'SUBSIDIARY') }} sub 
        ON sub.ID=tl.SUBSIDIARY
    LEFT JOIN {{ get_gold_source(company, 'DIM_CHART_OF_ACCOUNT') }} coa 
        ON 
            {% if company == 'wagway' %}
             HASH(tal.ACCOUNT, tl.SUBSIDIARY,tl.CLASS,tl.LOCATION,tl.DEPARTMENT,tl.ADDBACK_ID) = coa.DIM_CHART_OF_ACCOUNT_ID
            {% else %}
                HASH(tal.ACCOUNT, tl.SUBSIDIARY,tl.CLASS,tl.LOCATION,tl.DEPARTMENT) = coa.DIM_CHART_OF_ACCOUNT_ID
            {% endif %}
    LEFT JOIN {{ get_silver_source(company, 'CONSOLIDATEDEXCHANGERATE') }} cer
        ON cer.POSTINGPERIOD = t.POSTINGPERIOD 
        AND cer.FROMSUBSIDIARY=tl.SUBSIDIARY
        AND cer.TOSUBSIDIARY=COALESCE(sub.PARENT,1)

 
)

SELECT * FROM source
{% if company == 'playfly' %}
        WHERE 
            COALESCE(lower(STATUS_NAME), '') <> 'rejected'
            AND IS_POSTING = TRUE
{% endif %}