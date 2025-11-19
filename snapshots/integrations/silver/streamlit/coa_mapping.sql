{% snapshot coa_mapping %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{% set src = 'streamlit'%}
{% set src_table = company ~ '_coa_mapping' %}


{{
    config(
        enabled = var('sourcesystem') == 'netsuite',
        database = get_target_database(company),
        target_schema = 'silver',
        alias = sourcesystem ~ '_COA', 
        unique_key = 'coa_id',
        strategy = 'check',
        check_cols = ['METRIC_L1', 'METRIC_L2', 'METRIC_L3', 'METRIC_L4', 'METRIC_L5', 'METRIC_L6', 'CASHFLOW_L1', 'CASHFLOW_L2', 'CASHFLOW_L3', 'IS_BS', 'DEBT_MAPPING'],
        invalidate_hard_deletes = True
    )
}}


SELECT 
    COA_ID,
    ACCOUNT_ID,
    SUBSIDIARY_ID,
    CLASS_ID,
    LOCATION_ID,
    DEPARTMENT_ID,
    
    {%if company == 'wagway' %}
        ADJUSTMENT_ID,
    {%endif%}
    LOCATION_NAME,
    SUBSIDIARY_NAME,
    ACCOUNT_NAME,
    CLASS_NAME,
    DEPARTMENT_NAME,
    {%if company == 'wagway' %}
        ADJUSTMENT_NAME,
    {%endif%}
    METRIC_L1,
    METRIC_L2,
    METRIC_L3,
    METRIC_L4,
    METRIC_L5,
    METRIC_L6,
    CASHFLOW_L1,
    CASHFLOW_L2,
    CASHFLOW_L3,
    IS_BS,
    DEBT_MAPPING,
    DATA_LOADED_AT
FROM {{ source(src, src_table) }}

{% endsnapshot %}