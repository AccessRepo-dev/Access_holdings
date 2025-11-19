{% snapshot adjustments %}

{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{% set src = 'streamlit'%}
{% set src_table = company ~ '_adjustments' %}


{{
    config(
        enabled = var('sourcesystem') == 'netsuite' and var('company') | lower =='wagway',
        database = get_target_database(company),
        target_schema = 'silver',
        alias = sourcesystem ~ '_Adjustments', 
        unique_key = 'unique_key',
        strategy = 'check',
        check_cols = ['AMOUNT'],
        invalidate_hard_deletes = True
    )
}}


SELECT 
    DISTINCT 
    HASH(ACCOUNT_ID, SUBSIDIARY_ID, CLASS_ID,LOCATION_ID,DEPARTMENT_ID,ADJUSTMENT_ID,ADJ_TYPE,PERIOD) AS unique_key,
    HASH(ACCOUNT_ID, SUBSIDIARY_ID, CLASS_ID,LOCATION_ID,DEPARTMENT_ID,ADJUSTMENT_ID) AS COA_ID ,
    ACCOUNT_ID,
    SUBSIDIARY_ID,
    CLASS_ID,
    LOCATION_ID,
    DEPARTMENT_ID,
    ADJUSTMENT_ID,
    LOCATION_NAME,
    SUBSIDIARY_NAME,
    ACCOUNT_NAME,
    CLASS_NAME,
    DEPARTMENT_NAME,
    ADJUSTMENT_NAME,
    ADJ_TYPE,
    PERIOD,
    AMOUNT

FROM {{ source(src, src_table) }}

{% endsnapshot %}
