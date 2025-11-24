{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') | lower == 'netsuite') }}

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
        t.POSTINGPERIOD AS DIM_PERIOD_ID
        ,
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
        NULL AS ADJ_TYPE,
        t.LASTMODIFIEDDATE
        
    FROM {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_TRANSACTIONLINE') }} tl
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_TRANSACTION') }} t
        ON t.ID = tl.TRANSACTION
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_TRANSACTIONACCOUNTINGLINE') }} tal
        ON tl.transaction = tal.transaction and tl.id = tal.transactionline
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_ACCOUNT') }} a
        ON a.ID = tal.ACCOUNT
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_ACCOUNTINGPERIOD') }} per
        ON per.ID = t.POSTINGPERIOD
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_TRANSACTIONSTATUS') }} txs
        ON txs.ID = t.status and txs.trantype = t.type and t.customtype = txs.trancustomtype
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_SUBSIDIARY') }} sub 
        ON sub.ID=tl.SUBSIDIARY
    LEFT JOIN {{ get_gold_source(company, 'DIM_CHART_OF_ACCOUNT') }} coa 
        ON 
            {% if company == 'wagway' %}
             HASH(tal.ACCOUNT, tl.SUBSIDIARY,tl.CLASS,tl.LOCATION,tl.DEPARTMENT,tl.ADDBACK_ID) = coa.DIM_CHART_OF_ACCOUNT_ID
            {% else %}
                HASH(tal.ACCOUNT, tl.SUBSIDIARY,tl.CLASS,tl.LOCATION,tl.DEPARTMENT) = coa.DIM_CHART_OF_ACCOUNT_ID
            {% endif %}
    LEFT JOIN {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_CONSOLIDATEDEXCHANGERATE') }} cer
        ON cer.POSTINGPERIOD = t.POSTINGPERIOD 
        AND cer.FROMSUBSIDIARY=tl.SUBSIDIARY
        AND cer.TOSUBSIDIARY=COALESCE(sub.PARENT,1)

 
),
adjustments AS (
    SELECT
        CONCAT('ADJ-', CAST(COA_ID AS VARCHAR), '-', CAST(PERIOD AS VARCHAR))  AS  TRANSACTIONS_UNIQUE_ID,
        NULL AS TRANSACTION_ID,
        NULL TRANSACTION_LINE_ID,
        NULL TRANSACTION_NUMBER,
        NULL TRANID,
        NULL AS TRANSACTION_TYPE,
        NULL AS STATUS,
        NULL AS TITLE,
        NULL AS STATUS_NAME,
        
        -- Chart of accounts
        ACCOUNT_ID,
        TRUE AS IS_POSTING,
        NULL ACCOUNT_NUMBER,
        NULL AS ACCOUNT_TYPE,
        ACCOUNT_NAME,
        CASE WHEN ADJ_TYPE = 'Lender Adjustment' THEN -18
        WHEN ADJ_TYPE = 'Pro-Forma Adjustment' THEN -19 
        ELSE COA_ID 
        END AS DIM_CHART_OF_ACCOUNT_ID,
        
        CLASS_ID AS DIM_CLASS_ID,
        NULL AS DIM_PROJECT_ID,
        
        -- Transaction line details
        NULL  AS DIM_ITEM_ID,
        DEPARTMENT_ID AS DIM_DEPARTMENT_ID,
        NULL AS DIM_ENTITY_ID,
        NULL AS TRANSACTION_LINE_TYPE,
        NULL AS ACCOUNTING_LINE_TYPE,
        LOCATION_ID AS DIM_LOCATION_ID,
        SUBSIDIARY_ID AS DIM_SUBSIDIARY_ID,
        {%if comapny == 'wagway'%}
            ADJUSTMENT_ID AS DIM_ADDBACK_ID,
        {%else%}
            0 as DIM_ADDBACK_ID,
        {% endif %}
        -- Period / currency
        NULL AS DIM_PERIOD_ID,
        NULL AS POSTING_PERIOD_DATE,
        NULL AS CURRENCY,  -- Assuming USD or base currency
        NULL AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        1 AS EXCHANGERATE,
        
        -- Amounts
        AMOUNT AS NETAMOUNT,
        AMOUNT AS AMOUNT_UNCONVERTED,
        AMOUNT AS AMOUNT,
        AMOUNT AS CONVERTED_NET_AMOUNT,
        1 AS AVERAGERATE,
        1 AS CURRENTRATE,
        1 AS HISTORICALRATE,
        AMOUNT AS AMOUNT_AR,
        AMOUNT AS AMOUNT_CR,
        AMOUNT AS AMOUNT_HR,
        NULL AS BOM_QUANTITY,
        NULL AS QUANTITY,
        
        -- Employee / address / customer
        NULL AS EMPLOYEE,
        NULL AS BILLINGADDRESS,
        NULL AS SHIPPINGADDRESS,
        NULL AS BILLINGSTATUS,
        NULL AS MEMO,
        
        -- Dates
        NULL AS TRANDATE,
        NULL AS STARTDATE,
        TO_DATE(PERIOD || '-01', 'MON-YY-DD') AS PERIOD_START_DATE,
        NULL AS ENDDATE,
        NULL AS DUEDATE,
        NULL AS CLOSEDATE,
        ADJ_TYPE, 
        CURRENT_TIMESTAMP AS LASTMODIFIEDDATE
     
    FROM  {{ get_silver_source(company, 'netsuite_adjustments') }} tl
    
    {% if is_incremental() %}
    -- First, remove old adjustment records
    DELETE FROM {{ this }}
    WHERE TRANSACTIONS_UNIQUE_ID LIKE 'ADJ-%';
{% endif %}
    WHERE dbt_valid_to IS NULL  
)

SELECT * FROM source
{% if company == 'playfly' %}
        WHERE 
            COALESCE(lower(STATUS_NAME), '') <> 'rejected'
            AND IS_POSTING = TRUE
{% endif %}

UNION 
SELECT * FROM adjustments
