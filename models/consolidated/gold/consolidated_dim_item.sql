{{ config(
    materialized = 'incremental',
    alias = 'dim_item',
    incremental_strategy = 'merge',
    unique_key = ['DIM_ITEM_ID']
) }}


{% set companies = var('companies') %}

{% for c in companies if c.name | lower != 'zeus' %}
    select
        HASH(DIM_ITEM_ID, '{{ c.name }}','{{ c.source }}') AS DIM_ITEM_ID,
        DIM_ITEM_ID AS ITEM_ID,
        ITEM_NAME,
        DISPLAY_NAME,
        STORE_DISPLAY_NAME,
        DESCRIPTION,
        STORE_DESCRIPTION,
        ITEM_TYPE,
        SUB_TYPE,
        CLASS_ID,
        DEPARTMENT_ID,
        LOCATION_ID,
        SUBSIDIARY_ID,
        PARENT_ID,
        PRICING_GROUP,
        UNITS_TYPE,
        INCOME_ACCOUNT,
        COSTING_METHOD,
        COST,
        LAST_PURCHASE_PRICE,
        AVERAGE_COST,
        TOTAL_QUANTITY_ON_HAND,
        TOTAL_VALUE,
        SALE_UNIT,
        STOCK_UNIT,
        SHIPPING_COST,
        VENDOR_NAME,
        MANUFACTURER,
        MAXIMUM_QUANTITY,
        WEIGHT,
        IS_FULFILLABLE,
        IS_INACTIVE,
        CREATED_DATE,
        LAST_MODIFIED_DATE,
        '{{ c.source }}' AS SOURCESYSTEM,
        '{{ c.name }}' AS COMPANY,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
    from {{ render(c.db) }}.GOLD.DIM_ITEM
    {% if not loop.last %} union all {% endif %}
{% endfor %}
