{% snapshot coa_mapping %}

{% set company = var('company','wagway') | lower %}
{% set sourcesystem = var('sourcesystem','netsuite') %}
{% set src = 'streamlit'%}
{% set src_table = company ~ '_coa_mapping' %}


{{
    config(
        enabled = var("company",'wagway') | lower in ('wagway','playfly','amh','spotless'),
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
    CLASS_ID,
    LOCATION_ID,
    DEPARTMENT_ID,
    {%if sourcesystem == 'netsuite' %}
        ADJUSTMENT_ID,
        ADJUSTMENT_NAME,
    {%endif%}
    LOCATION_NAME,
    ACCOUNT_NAME,
    ACCOUNT_NUMBER,
    CLASS_NAME,
    DEPARTMENT_NAME,
    {%if sourcesystem == 'netsuite' %}
        SUBSIDIARY_NAME,
         SUBSIDIARY_ID,
    {%endif%}
    {%if sourcesystem == 'sage' %}
        PROJECT_NAME,
        PROJECT_ID,
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