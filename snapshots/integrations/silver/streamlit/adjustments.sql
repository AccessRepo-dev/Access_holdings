{% snapshot adjustments %}

{% set company = var('company') | lower %}
{% set sourcesystem = var('sourcesystem') %}
{% set src = 'streamlit'%}
{% set src_table = company ~ '_adjustments' %}


{{
    config(
        enabled = var("company") | lower in ('wagway','playfly','amh','spotless'),
        database = get_target_database(company),
        target_schema = 'silver',
        alias = sourcesystem ~ '_Adjustments', 
        unique_key = ['ACCOUNT_ID', 'SUBSIDIARY_ID', 'CLASS_ID','LOCATION_ID','DEPARTMENT_ID','ADJUSTMENT_ID','ADJ_TYPE','PERIOD'],
        strategy = 'check',
        check_cols = ['AMOUNT'],
        invalidate_hard_deletes = True
    )
}}
{%if sourcesystem == 'netsuite'%}
{{
    config( 
        unique_key = ['ACCOUNT_ID', 'SUBSIDIARY_ID', 'CLASS_ID','LOCATION_ID','DEPARTMENT_ID','ADJUSTMENT_ID','ADJ_TYPE','PERIOD']
       
    )
}}
{%else%}
{{
 config( 
        unique_key = ['ACCOUNT_ID', 'LOCATION_ID', 'DEPARTMENT_ID','','PROJECT_ID','CLASS_ID','ADJ_TYPE','PERIOD']   
    )
    }}
{%endif%}

SELECT 
    DISTINCT 
    {%if sourcesystem == 'netsuite'%}
    HASH(ACCOUNT_ID, SUBSIDIARY_ID, CLASS_ID,LOCATION_ID,DEPARTMENT_ID,ADJUSTMENT_ID,ADJ_TYPE,PERIOD) AS unique_key,
    HASH(
        ACCOUNT_ID, SUBSIDIARY_ID, CLASS_ID,LOCATION_ID,DEPARTMENT_ID,ADJUSTMENT_ID) AS COA_ID ,
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
    {%endif%}
    LOCATION_NAME,
    ACCOUNT_NAME,
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
    ADJ_TYPE,
    PERIOD,
    AMOUNT

FROM {{ source(src, src_table) }}

{% endsnapshot %}
