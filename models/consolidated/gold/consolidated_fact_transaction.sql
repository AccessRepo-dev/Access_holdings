{{ config(
    materialized = 'incremental',
    alias = 'fact_transaction',
    incremental_strategy = 'merge',
    unique_key = 'FACT_TRANSACTION_ID'
) }}

{% set companies = var('companies') %}

{% for c in companies %}
    select
        {% if c.name == 'ZEUS' %}  HASH(TRANSACTION_UNIQUE_ID, '{{ c.name }}','{{ c.source }}') AS FACT_TRANSACTION_ID, {% else %}  HASH(TRANSACTIONS_UNIQUE_ID, '{{ c.name }}','{{ c.source }}') AS FACT_TRANSACTION_ID, {% endif %}
        TRANSACTIONS_UNIQUE_ID ,
        TRANSACTION_ID ,
        TRANSACTION_LINE_ID,
        TRANSACTION_NUMBER,
        TRANID,
        TRANSACTION_TYPE,
        STATUS,
        TITLE,
        STATUS_NAME,
        ACCOUNT_ID,
        IS_POSTING,
        ACCOUNT_NUMBER,
        ACCOUNT_TYPE,
        ACCOUNT_NAME,
        HASH(DIM_CHART_OF_ACCOUNT_ID,'{{ c.name }}','{{ c.source }}') AS  DIM_CHART_OF_ACCOUNT_ID,
        HASH(DIM_CLASS_ID,'{{ c.name }}','{{ c.source }}') AS DIM_CLASS_ID,
        DIM_PROJECT_ID,
        HASH(DIM_ITEM_ID,'{{ c.name }}','{{ c.source }}') AS  DIM_ITEM_ID,
        HASH(DIM_DEPARTMENT_ID,'{{ c.name }}','{{ c.source }}') AS DIM_DEPARTMENT_ID,
        DIM_ENTITY_ID,
        TRANSACTION_LINE_TYPE,
        ACCOUNTING_LINE_TYPE,
        HASH(DIM_LOCATION_ID,'{{ c.name }}','{{ c.source }}') AS DIM_LOCATION_ID,
        HASH(DIM_SUBSIDIARY_ID,'{{ c.name }}','{{ c.source }}') AS DIM_SUBSIDIARY_ID,
        DIM_ADDBACK_ID,
        HASH(DIM_PERIOD_ID, '{{ c.name }}','{{ c.source }}') AS DIM_PERIOD_ID,
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
        PERIOD_START_DATE,
        ENDDATE,
        DUEDATE,
        CLOSEDATE,
        LASTMODIFIEDDATE,
        '{{ c.source }}' as SOURCESYSTEM,
        '{{ c.name }}' as COMPANY,
        current_timestamp()::timestamp_ntz as CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.FACT_TRANSACTION

    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LASTMODIFIEDDATE), '1900-01-01')
        from {{ this }}
        where SOURCESYSTEM = '{{ c.source }}' and COMPANY = '{{ c.name }}'
    )
    {% endif %}
    {% if not loop.last %} union all {% endif %}
{% endfor %}
