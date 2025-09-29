{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'fact_transaction'
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
        map.METRIC_L1,
        map.METRIC_L2,
        map.METRIC_L3,
        map.METRIC_L4,
        map.METRIC_L5,
        map.METRIC_L6,
        
        -- Transaction line details
        tl.ITEM AS DIM_ITEM_ID,
        tl.DEPARTMENT AS DIM_DEPARTMENT_ID,
        tl.ENTITY AS DIM_ENTITY_ID,
        tl.TRANSACTIONLINETYPE AS TRANSACTION_LINE_TYPE,
        tl.ACCOUNTINGLINETYPE AS ACCOUNTING_LINE_TYPE,
        tl.LOCATION AS DIM_LOCATION_ID,
        tl.SUBSIDIARY AS DIM_SUBSIDIARY_ID,
        
        {% if company == 'wagway' and sourcesystem == 'netsuite' %}
            tl.ADDBACK_ID AS DIM_ADDBACK_ID,
        {% else %}
            NULL AS DIM_ADDBACK_ID,
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
    LEFT JOIN {{ get_silver_source(company, 'NETSUITE_COA_MAPPING') }} map
        ON ABS(HASH(tal.ACCOUNT, tl.SUBSIDIARY)) = ABS(HASH(map.ACCOUNT_ID, map.SUBSIDIARY_ID))
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
        NULL AS IS_POSTING,
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
