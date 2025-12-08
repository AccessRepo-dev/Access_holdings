{% snapshot adjustments %}

{% set company = var('company','wagway') | lower %}
{% set sourcesystem = var('sourcesystem','netsuite') %}
{% set src = 'streamlit'%}
{% set src_table = company ~ '_adjustments' %}


{{
    config(
        enabled = var('company','wagway') | lower in ('wagway','playfly','amh','spotless','zeus'),
        database = get_target_database(company),
        target_schema = 'silver',
        alias = sourcesystem ~ '_Adjustments', 
        strategy = 'check',
        check_cols = ['AMOUNT','LAST_UPDATED_AT','LAST_UPDATED_BY'],
        invalidate_hard_deletes = True
    )
}}
{%if sourcesystem == 'netsuite'%}
    {{
        config( unique_key = ['ACCOUNT_ID', 'SUBSIDIARY_ID', 'CLASS_ID','LOCATION_ID','DEPARTMENT_ID','ADJUSTMENT_ID','ADJ_TYPE','PERIOD'] )
    }}
{%elif sourcesystem == 'sage' %}
    {{
    config( 
            unique_key = ['ACCOUNT_ID', 'LOCATION_ID', 'DEPARTMENT_ID','PROJECT_ID','CLASS_ID','ADJ_TYPE','PERIOD']  )
        }}
{%else%}
    {{
    config( 
            unique_key = ['SUBSIDIARY_ID','COA_ID','ADJ_TYPE','PERIOD']  )
        }}
{%endif%}

{%if company == 'zeus'%}
SELECT 
    DISTINCT
    HASH(SUBSIDIARY_ID,COA_ID,ADJ_TYPE,PERIOD) AS  unique_key,
    SUBSIDIARY_ID,
    COA_ID,
    ADJ_TYPE,
    PERIOD,
    AMOUNT,
    CREATED_AT,
    CREATED_BY,
    LAST_UPDATED_AT,
    LAST_UPDATED_BY
    
FROM {{ source(src, src_table) }}
{%else%}
SELECT 
    DISTINCT 
    {%if sourcesystem == 'netsuite'%}
    HASH(ACCOUNT_ID, SUBSIDIARY_ID, CLASS_ID,LOCATION_ID,DEPARTMENT_ID,ADJUSTMENT_ID,ADJ_TYPE,PERIOD) AS unique_key,
    HASH(ACCOUNT_ID, SUBSIDIARY_ID, CLASS_ID,LOCATION_ID,DEPARTMENT_ID,ADJUSTMENT_ID) AS COA_ID ,
    {%elif sourcesystem == 'sage'%}
    HASH(ACCOUNT_ID, LOCATION_ID,DEPARTMENT_ID,PROJECT_ID, CLASS_ID,ADJ_TYPE,PERIOD) AS unique_key,
    HASH(ACCOUNT_ID, LOCATION_ID,DEPARTMENT_ID,PROJECT_ID, CLASS_ID) AS COA_ID ,
    {%endif%}
    ACCOUNT_ID,
    CLASS_ID,
    LOCATION_ID,
    DEPARTMENT_ID,
     {%if sourcesystem == 'netsuite' %}
        ADJUSTMENT_ID,
        ADJUSTMENT_NAME,
        SUBSIDIARY_NAME,
        SUBSIDIARY_ID,
    {%endif%}
    LOCATION_NAME,
    ACCOUNT_NAME,
    CLASS_NAME,
    DEPARTMENT_NAME,
    {%if sourcesystem == 'sage' %}
        PROJECT_NAME,
        PROJECT_ID,
    {%endif%}
    ADJ_TYPE,
    PERIOD,
    AMOUNT,
    CREATED_AT,
    CREATED_BY,
    LAST_UPDATED_AT,
    LAST_UPDATED_BY

FROM {{ source(src, src_table) }}
{%endif%}
{% endsnapshot %}
