{% snapshot coa_mapping %}

{% set company = var('company','wagway') | lower %}
{% set sourcesystem = var('sourcesystem') %}
{% set src = 'streamlit'%}
{% set src_table = company ~ '_coa_mapping' %}
{% set is_ci = var('is_ci_run', false) %}

{# Determine schema based on CI/CD mode #}
{% if is_ci %}
    {% set snapshot_schema = target.schema %}
    {{ log("CI MODE - Using schema: " ~ snapshot_schema, info=True) }}
{% else %}
    {% set snapshot_schema = 'silver' %}
    {{ log("CD MODE - Using schema: " ~ snapshot_schema, info=True) }}
{% endif %}

{{
    config(
        enabled = var('company','wagway') | lower in ('wagway','playfly','amh','spotless','zeus')
        and (var("sourcesystem", "netsuite") | lower) in ["streamlit", "netsuite", "sage"],
        database = get_target_database(company),
        target_schema = snapshot_schema,
        alias = sourcesystem ~ '_COA', 
        unique_key = 'coa_id',
        strategy = 'check',
        check_cols = ['METRIC_L1', 'METRIC_L2', 'METRIC_L3', 'METRIC_L4', 'METRIC_L5', 'METRIC_L6', 'CASHFLOW_L1', 'CASHFLOW_L2', 'CASHFLOW_L3', 'IS_BS', 'DEBT_MAPPING', 'LAST_UPDATED_AT',
    'LAST_UPDATED_BY'],
        invalidate_hard_deletes = True,
        on_schema_change='append_new_columns'
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
    LAST_UPDATED_AT,
    LAST_UPDATED_BY,
    DEBT_MAPPING,
    DATA_LOADED_AT
FROM {{ source(src, src_table) }}


{% endsnapshot %}
