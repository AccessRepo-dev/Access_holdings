{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem') == 'sedona' and var('company') == 'zeus'  ) }}
 
{{ config(
    database = get_target_database(company),
    alias = 'fact_transaction',
    materialized = 'table',
    unique_key = 'TRANSACTIONS_UNIQUE_ID'
) }}
 


    SELECT
        CONCAT(CAST(ADJ_TYPE AS VARCHAR),'-', CAST(COA_ID AS VARCHAR), '-', CAST(PERIOD AS VARCHAR))  AS  TRANSACTIONS_UNIQUE_ID,
        NULL AS TRANSACTION_ID,
        NULL TRANSACTION_LINE_ID,
        NULL TRANSACTION_NUMBER,
        NULL TRANID,
        NULL AS TRANSACTION_TYPE,
        NULL AS STATUS,
        NULL AS TITLE,
        NULL AS STATUS_NAME,
        
        -- Chart of accounts
        NULL AS ACCOUNT_ID,
        TRUE AS IS_POSTING,
        NULL ACCOUNT_NUMBER,
        NULL AS ACCOUNT_TYPE,
        NULL AS ACCOUNT_NAME,
        CASE WHEN ADJ_TYPE = 'Lender Adjustment' THEN -18
        WHEN ADJ_TYPE = 'Pro-Forma Adjustment' THEN -19 
        ELSE COA_ID 
        END AS DIM_CHART_OF_ACCOUNT_ID,
        
        NULL AS DIM_CLASS_ID,
        NULL AS DIM_PROJECT_ID,
        
        -- Transaction line details
        NULL  AS DIM_ITEM_ID,
        NULL AS DIM_DEPARTMENT_ID,
        --NULL AS DIM_ENTITY_ID,
        NULL AS TRANSACTION_LINE_TYPE,
        NULL AS ACCOUNTING_LINE_TYPE,
        NULL AS DIM_LOCATION_ID,
        NULL AS DIM_ENTITY_ID,
        SUBSIDIARY_ID AS DIM_SUBSIDIARY_ID,
       
        NULL as DIM_ADDBACK_ID,
       
        -- Period / currency
        NULL AS DIM_PERIOD_ID,
        NULL AS POSTING_PERIOD_DATE,
        NULL AS CURRENCY,  -- Assuming USD or base currency
        NULL AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        NULL AS EXCHANGERATE,
        
        -- Amounts
        AMOUNT AS NETAMOUNT,
        AMOUNT, 
        AMOUNT AS AMOUNT_UNCONVERTED,
        
        AMOUNT AS CONVERTED_NET_AMOUNT,
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
        ADJ_TYPE ,
        CURRENT_TIMESTAMP AS LASTMODIFIEDDATE
     
    FROM  {{ get_silver_source(company, 'sedona_adjustments') }} tl
    



