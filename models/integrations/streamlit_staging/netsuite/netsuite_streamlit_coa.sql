{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{% set src = var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw'%}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}


{% set hook_src = var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw' %}

{{ config(
    enabled = var('sourcesystem') == 'netsuite',
    pre_hook=[
        "{{ replicate_table_from_dev(
            source_database= 'STREAMLIT_APPS',
            source_schema='FINMAP_DEV',
            table_name = var('company') ~ '_COA_MAPPING'
        ) }}",
        """
         {% if is_incremental() %}
MERGE INTO {{ this }} tgt
USING (
    SELECT
        t.COA_ID,
        COALESCE(a.FULLNAME, 'Unknown') AS ACCOUNT_NAME,
        COALESCE(s.NAME, 'Unknown')     AS SUBSIDIARY_NAME,
        COALESCE(c.NAME, 'Unknown')     AS CLASS_NAME,
        COALESCE(d.FULLNAME, 'Unknown') AS DEPARTMENT_NAME,
        {% if var('company') | lower == 'wagway' %}
        COALESCE(l.NAME, 'Unknown')     AS LOCATION_NAME,
        COALESCE(ad.NAME, 'Unknown')    AS ADJUSTMENT_NAME
        {% else %}
        COALESCE(l.NAME, 'Unknown')     AS LOCATION_NAME,
        COALESCE(ad.NAME, 'Unknown')    AS ADJUSTMENT_NAME
        {% endif %}

    FROM (SELECT DISTINCT COA_ID, ACCOUNT_ID, SUBSIDIARY_ID, CLASS_ID, LOCATION_ID, DEPARTMENT_ID, ADJUSTMENT_ID FROM {{ this }}) t

    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'ACCOUNT') }} a
        ON a.ID = t.ACCOUNT_ID
    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'SUBSIDIARY') }} s
        ON s.ID = t.SUBSIDIARY_ID
    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'CLASSIFICATION') }} c
        ON c.ID = t.CLASS_ID
    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'DEPARTMENT') }} d
        ON d.ID = t.DEPARTMENT_ID
    {% if var('company') | lower == 'wagway' %}
    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'CUSTOMRECORD_CSEG_CP_STORE_LOC') }} l
        ON l.ID = t.LOCATION_ID
    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'CUSTOMRECORD_CSEG1') }} ad
        ON ad.ID = t.ADJUSTMENT_ID
    {% else %}
    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'LOCATION') }} l
        ON l.ID = t.LOCATION_ID
    LEFT JOIN {{ source(var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw', 'CUSTOMRECORD_CSEG2') }} ad
        ON ad.ID = t.ADJUSTMENT_ID
    {% endif %}

) src ON tgt.COA_ID = src.COA_ID

WHEN MATCHED AND NOT (
    EQUAL_NULL(tgt.ACCOUNT_NAME,    src.ACCOUNT_NAME)    AND
    EQUAL_NULL(tgt.SUBSIDIARY_NAME, src.SUBSIDIARY_NAME) AND
    EQUAL_NULL(tgt.CLASS_NAME,      src.CLASS_NAME)      AND
    EQUAL_NULL(tgt.DEPARTMENT_NAME, src.DEPARTMENT_NAME) AND
    EQUAL_NULL(tgt.LOCATION_NAME,   src.LOCATION_NAME)   AND
    EQUAL_NULL(tgt.ADJUSTMENT_NAME, src.ADJUSTMENT_NAME)
)
THEN UPDATE SET
    tgt.ACCOUNT_NAME    = src.ACCOUNT_NAME,
    tgt.SUBSIDIARY_NAME = src.SUBSIDIARY_NAME,
    tgt.CLASS_NAME      = src.CLASS_NAME,
    tgt.DEPARTMENT_NAME = src.DEPARTMENT_NAME,
    tgt.LOCATION_NAME   = src.LOCATION_NAME,
    tgt.ADJUSTMENT_NAME = src.ADJUSTMENT_NAME
{% endif %}
        """
    ],
    materialized = 'incremental',
    alias = company ~ '_COA_MAPPING',
    incremental_strategy = 'merge',
    unique_key = 'COA_ID'
) }}

with transaction as (
    SELECT 
    DISTINCT
   

    {% if company == 'wagway' %}
            hash(
            coalesce(tal.account, 0),
            coalesce(tl.subsidiary, 0),
            coalesce(tl.class, 0),
            coalesce(tl.cseg_cp_store_loc, 0),
            coalesce(tl.department, 0),
            coalesce(tl.cseg1, 0)
            ) AS COA_ID,
    {% else %}
            hash(
            coalesce(tal.account, 0),
            coalesce(tl.subsidiary, 0),
            coalesce(tl.class, 0),
            coalesce(tl.location, 0),
            coalesce(tl.department, 0),
            coalesce(tl.CSEG2,0)
    ) AS COA_ID,
    {% endif %}
    COALESCE(tal.ACCOUNT, 0) AS ACCOUNT_ID,
    COALESCE(a.ACCTNUMBER,'Unknown') AS ACCOUNT_NUMBER,
    COALESCE(tl.SUBSIDIARY, 0) AS SUBSIDIARY_ID,
    COALESCE(tl.CLASS, 0) AS CLASS_ID,
    {%if company == 'wagway'%}
    COALESCE(tl.CSEG_CP_STORE_LOC, 0) AS LOCATION_ID,
    {%else %}
    COALESCE(tl.LOCATION, 0) AS LOCATION_ID,
    {%endif%}
    
    COALESCE(tl.DEPARTMENT, 0) AS DEPARTMENT_ID,
    {%if company == 'wagway'%}
    COALESCE(tl.CSEG1, 0)  AS ADJUSTMENT_ID,
    {%else%}
     COALESCE(tl.CSEG2, 0)  AS ADJUSTMENT_ID,
    {%endif%}
   
    COALESCE(l.NAME, 'Unknown') AS LOCATION_NAME,
    COALESCE(s.NAME, 'Unknown') AS SUBSIDIARY_NAME,
    COALESCE(a.FULLNAME, 'Unknown') AS ACCOUNT_NAME,
    COALESCE(c.NAME, 'Unknown') AS CLASS_NAME,
    COALESCE(d.FULLNAME, 'Unknown') AS DEPARTMENT_NAME,
    COALESCE(ad.name, 'Unknown') AS ADJUSTMENT_NAME,
   
    CURRENT_TIMESTAMP AS DATA_LOADED_AT 


FROM {{ source(src, 'TRANSACTIONLINE') }} tl
LEFT JOIN {{ source(src, 'TRANSACTIONACCOUNTINGLINE') }} tal ON tl.TRANSACTION = tal.TRANSACTION AND tl.ID = tal.TRANSACTIONLINE
LEFT JOIN {{ source(src, 'ACCOUNT') }} a ON a.ID = tal.ACCOUNT
LEFT JOIN {{ source(src, 'CLASSIFICATION') }} c ON c.ID = COALESCE(tl.CLASS, 0)
{%if company == 'wagway'%}
    LEFT JOIN {{ source(src, 'CUSTOMRECORD_CSEG_CP_STORE_LOC') }} l ON l.ID = COALESCE(tl.CSEG_CP_STORE_LOC, 0)
    LEFT JOIN {{ source(src, 'CUSTOMRECORD_CSEG1') }} ad ON COALESCE(tl.CSEG1, 0) = ad.ID
{%else%}
    LEFT JOIN {{ source(src, 'LOCATION') }} l ON l.ID = COALESCE(tl.location, 0)
    LEFT JOIN {{ source(src, 'CUSTOMRECORD_CSEG2') }} ad ON COALESCE(tl.CSEG2, 0) = ad.ID
{%endif%}
LEFT JOIN {{ source(src, 'SUBSIDIARY') }} s ON s.ID = COALESCE(tl.SUBSIDIARY, 0)
LEFT JOIN {{ source(src, 'DEPARTMENT') }} d ON d.ID = COALESCE(tl.DEPARTMENT, 0)

{% if is_incremental() %}
    where COA_ID not in (
        select COA_ID
        from {{ this }}
    )
{% endif %}
),
budget as (
    SELECT DISTINCT 
        {%if company == 'wagway'%}
        hash(
            coalesce(b.account, 0),
            coalesce(b.subsidiary, 0),
            coalesce(b.class, 0),
            coalesce(b.CSEG_CP_STORE_LOC, 0),
            coalesce(b.department, 0),
            coalesce(b.cseg1, 0)
        ) AS COA_ID,
        {%else %}
        hash(
            coalesce(b.account, 0),
            coalesce(b.subsidiary, 0),
            coalesce(b.class, 0),
            coalesce(b.location, 0),
            coalesce(b.department, 0),
            0 
        ) AS COA_ID,
         {% endif %}
        COALESCE(b.ACCOUNT, 0) AS ACCOUNT_ID,
        COALESCE(a.ACCTNUMBER,'Unknown') AS ACCOUNT_NUMBER,
        COALESCE(b.SUBSIDIARY, 0) AS SUBSIDIARY_ID,
        COALESCE(b.CLASS, 0) AS CLASS_ID,
        {%if company == 'wagway'%}
        COALESCE(b.CSEG_CP_STORE_LOC, 0) AS LOCATION_ID,
        {%else%}
        COALESCE(b.LOCATION, 0) AS LOCATION_ID,
        {%endif%} 
        COALESCE(b.DEPARTMENT, 0) AS DEPARTMENT_ID,
        {%if company == 'wagway'%}
        COALESCE(b.CSEG1, 0)   AS ADJUSTMENT_ID,
        {%else%}
        0 as ADJUSTMENT_ID,
        {%endif%} 
        COALESCE(l.NAME, 'Unknown') AS LOCATION_NAME,
        COALESCE(s.NAME, 'Unknown') AS SUBSIDIARY_NAME,
        COALESCE(a.FULLNAME, 'Unknown') AS ACCOUNT_NAME,
        COALESCE(c.NAME, 'Unknown') AS CLASS_NAME,
        COALESCE(d.FULLNAME, 'Unknown') AS DEPARTMENT_NAME,
        {%if company == 'wagway'%}
        COALESCE(ad.name, 'Unknown')   AS ADJUSTMENT_NAME,
        {%else%}
        'Unknown' as ADJUSTMENT_NAME,  
        {%endif%} 
       CURRENT_TIMESTAMP AS DATA_LOADED_AT 
        FROM {{ source(src, 'BUDGETLEGACY') }} b
    LEFT JOIN {{ source(src, 'ACCOUNT') }} a ON a.ID = COALESCE(b.ACCOUNT, 0)
    LEFT JOIN {{ source(src, 'CLASSIFICATION') }} c ON c.ID = COALESCE(b.CLASS, 0)
    {%if company == 'wagway'%}
    LEFT JOIN {{ source(src, 'CUSTOMRECORD_CSEG_CP_STORE_LOC') }} l ON l.ID = COALESCE(b.CSEG_CP_STORE_LOC, 0)
    LEFT JOIN {{ source(src, 'CUSTOMRECORD_CSEG1') }} ad ON COALESCE(b.CSEG1, 0) = ad.ID
    {%else%}
    LEFT JOIN {{ source(src, 'LOCATION') }} l ON l.ID = COALESCE(b.LOCATION, 0)
    {%endif%}
    
    LEFT JOIN {{ source(src, 'SUBSIDIARY') }} s ON s.ID = COALESCE(b.SUBSIDIARY, 0)
    LEFT JOIN {{ source(src, 'DEPARTMENT') }} d ON d.ID = COALESCE(b.DEPARTMENT, 0)

    {% if is_incremental() %}
    where COA_ID not in (
        select COA_ID
        from {{ this }}
    )
    {% endif %}
),
combined as (
select * from budget
UNION  
SELECT * FROM transaction
) 

SELECT DISTINCT  a.*,
    b.METRIC_L1,
    b.METRIC_L2,
    b.METRIC_L3,
    b.METRIC_L4,
    b.METRIC_L5,
    b.METRIC_L6,
    b.CASHFLOW_L1,
    b.CASHFLOW_L2,
    b.CASHFLOW_L3,
    b.IS_BS,
    b.DEBT_MAPPING,
    NULL AS LAST_UPDATED_BY,
    NULL AS LAST_UPDATED_AT
    FROM combined a

{%if company == 'wagway'%}
    LEFT JOIN {{this}} b ON a.ACCOUNT_ID = b.ACCOUNT_ID AND a.SUBSIDIARY_ID = b.SUBSIDIARY_ID AND a.CLASS_ID = b.CLASS_ID
{%else%}
    LEFT JOIN {{this}} b ON a.ACCOUNT_ID = b.ACCOUNT_ID AND a.DEPARTMENT_ID = b.DEPARTMENT_ID AND a.CLASS_ID = b.CLASS_ID
{%endif%} 

    