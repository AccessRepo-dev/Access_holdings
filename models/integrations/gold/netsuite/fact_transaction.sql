{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (
    SELECT 
        CONCAT
        (
          COALESCE(CAST(tl.TRANSACTION AS VARCHAR), '0'), '-', 
          COALESCE(CAST(tl.ID AS VARCHAR), '0')
        )
        AS TRANSACTIONS_UNIQUE_ID,
        tl.TRANSACTION,
        t.TRANID,
        tl.ID,
        tal.ACCOUNT,
        tl.ITEM,
        tl.CLASS,
        CONCAT
        (tal.ACCOUNT, '-', tl.CLASS )AS CHART_OF_ACCOUNTS_UNIQUE_ID,
        t.POSTINGPERIOD,
        t.EMPLOYEE,
        tl.ENTITY,
        t.BILLINGADDRESS,
        t.SHIPPINGADDRESS,
        t.CURRENCY,
        CONCAT
        (tl.SUBSIDIARY, '-', t.POSTINGPERIOD, '-', t.CURRENCY) 
        AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        tl.SUBSIDIARY,
        t.ID AS T_ID,
        t.STATUS ,  
        tl.DEPARTMENT,
        a.ACCTNUMBER,
        a.ACCTTYPE,
        a.FULLNAME AS ACCOUNT_NAME,
        t.TYPE,
        t.TRANSACTIONNUMBER,
        tal.NETAMOUNT,
        tal.AMOUNT,
        tl.TRANSACTIONLINETYPE,
        tl.ITEMTYPE,
        tl.ACCOUNTINGLINETYPE,
        t.TITLE,
        tl.QUANTITY,
        t.MEMO,
        t.BILLINGSTATUS,
        t.TRANDATE,
        t.STARTDATE,
        t.ENDDATE,
        t.DUEDATE,
        t.CLOSEDATE,
        t.LASTMODIFIEDDATE,
        ROUND(tal.NETAMOUNT * t.EXCHANGERATE, 2) AS CONVERTED_NET_AMOUNT,
        ROUND(tal.NETAMOUNT * CAST(tl.QUANTITY AS NUMBER), 2) AS BOM_QUANTITY,
        per.CLOSEDONDATE AS POSTING_PERIOD_DATE,
        txs.NAME
    
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
)
select *
from source