{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (
    SELECT 
       
        -- Unique identifiers
        CONCAT(
            COALESCE(CAST(tl.TRANSACTION AS VARCHAR), '0'), '-', 
            COALESCE(CAST(tl.ID AS VARCHAR), '0')
        ) AS TRANSACTIONS_UNIQUE_ID,
        tl.TRANSACTION,
        tl.ID,
        t.ID AS T_ID,
        t.TRANSACTIONNUMBER,
        t.TRANID,
        t.TYPE,
        t.STATUS,
        t.TITLE,
        txs.NAME,

        -- Chart of accounts / account details
        tal.ACCOUNT,
        tal.TRANSACTIONLINE,
        tal.POSTING,
        a.ACCTNUMBER,
        a.ACCTTYPE,
        a.FULLNAME AS ACCOUNT_NAME,
        ABS(HASH(tal.ACCOUNT, tl.SUBSIDIARY)) AS DIM_CHART_OF_ACCOUNT_ID,
        ABS(HASH(tl.CLASS, tl.SUBSIDIARY)) AS DIM_CLASS_ID,
        map.METRIC_L1,	
        map.METRIC_L2,
        map.METRIC_L3,
        map.METRIC_L4,
        map.METRIC_L5,
        map.METRIC_L6,

        -- Transaction line details
        tl.ITEM,
        tl.CLASS,
        tl.DEPARTMENT,
        tl.ENTITY,
        tl.ITEMTYPE,
        tl.TRANSACTIONLINETYPE,
        tl.ACCOUNTINGLINETYPE,
        tl.LOCATION,
        tl.SUBSIDIARY,
        tl.CREATEDFROM,
        tal.ACCOUNTINGBOOK,

        -- Period / currency / consolidation
        t.POSTINGPERIOD,
        per.CLOSEDONDATE AS POSTING_PERIOD_DATE,
        t.CURRENCY,
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

        
    FROM {{ get_silver_source(company, 'netsuite_transactionline') }}  tL
    JOIN  {{ get_silver_source(company, 'netsuite_transaction') }} t 
    ON t.ID = tl.TRANSACTION
    JOIN {{ get_silver_source(company, 'netsuite_transactionaccountingline') }} tal 
    ON  tl.transaction = tal.transaction and tl.id=tal.transactionline 
    LEFT JOIN {{ get_silver_source(company, 'netsuite_account') }} a 
    ON a.ID = tal.ACCOUNT
    LEFT JOIN {{ get_silver_source(company, 'netsuite_accountingperiod') }} per 
    ON per.ID = t.POSTINGPERIOD
    LEFT JOIN {{ get_silver_source(company, 'netsuite_transactionstatus') }} txs 
        ON txs.ID = t.status  and txs.trantype = t.type and t.customtype=txs.trancustomtype
    LEFT JOIN {{ get_silver_source(company, 'netsuite_coa_mapping') }} map
        ON ABS(HASH(tal.ACCOUNT, tl.SUBSIDIARY)) = ABS(HASH(map.ACCOUNT_ID, map.SUBSIDIARY_ID))
)
select *
from source