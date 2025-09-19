{{ config(
    materialized = 'incremental',
    alias = 'fact_transaction',
    incremental_strategy = 'merge',
    unique_key = ['FACT_TRANSACTION_ID',]
) }}

{% set companies = [
    {"name": "WAGWAY",   "db": env_var('DBT_WAGWAY'), "source": "NETSUITE"},
    {"name": "PLAYFLY",  "db": env_var('DBT_PLAYFLY'),  "source": "NETSUITE"},
    {"name": "SPOTLESS", "db": env_var('DBT_SPOTLESS'), "source": "SAGE"},
    {"name": "AMH",      "db": env_var('DBT_AMH'),   "source": "SAGE"}

 
] %}

{% for c in companies %}
    select
        HASH(TRANSACTIONS_UNIQUE_ID, '{{ c.name }}','{{ c.source }}') as FACT_TRANSACTION_ID,
        TRANSACTIONS_UNIQUE_ID ,
        CAST(TRANSACTION_ID AS INT) AS TRANSACTION_ID ,
        TRANSACTION_LINE_ID,
        TRANSACTION_NUMBER,
        TRANID,
        TRANSACTION_TYPE ,
        STATUS,
        TITLE,
        STATUS_NAME,
        ACCOUNT_ID,
        CAST(ACCOUNT_NUMBER AS VARCHAR) AS ACCOUNT_NUMBER ,
        ACCOUNT_TYPE,
        ACCOUNT_NAME,
        HASH(DIM_CHART_OF_ACCOUNT_ID,'{{ c.name }}','{{ c.source }}') AS  DIM_CHART_OF_ACCOUNT_ID,
        HASH(DIM_CLASS_ID,'{{ c.name }}','{{ c.source }}') AS DIM_CLASS_ID,
        METRIC_L1,
        METRIC_L2,
        METRIC_L3,
        METRIC_L4,
        METRIC_L5,
        METRIC_L6,
        HASH(DIM_ITEM_ID,'{{ c.name }}','{{ c.source }}') AS  DIM_ITEM_ID,
        HASH(DIM_DEPARTMENT_ID,'{{ c.name }}','{{ c.source }}') AS DIM_DEPARTMENT_ID,
        DIM_ENTITY_ID,
        TRANSACTION_LINE_TYPE,
        ACCOUNTING_LINE_TYPE,
        HASH(DIM_LOCATION_ID,'{{ c.name }}','{{ c.source }}') AS DIM_LOCATION_ID,
        HASH(DIM_SUBSIDIARY_ID,'{{ c.name }}','{{ c.source }}') AS DIM_SUBSIDIARY_ID,
        IS_POSTING,
        DIM_PERIOD_ID,
        POSTING_PERIOD_DATE,
        CURRENCY,
        CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
        EXCHANGERATE,
        NETAMOUNT,
        AMOUNT,
        CONVERTED_NET_AMOUNT,
        BOM_QUANTITY,
        QUANTITY,
        EMPLOYEE,
        BILLINGADDRESS,
        SHIPPINGADDRESS,
        BILLINGSTATUS,
        MEMO,
        TRANDATE,
        STARTDATE,
        ENDDATE,
        DUEDATE,
        CLOSEDATE,
        LASTMODIFIEDDATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ c.db }}.GOLD.FACT_TRANSACTION

    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LASTMODIFIEDDATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
