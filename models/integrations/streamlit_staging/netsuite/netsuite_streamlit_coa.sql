{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{% set src = var('company') | lower ~ '_' ~ var('sourcesystem') | lower ~ '_raw'%}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}



{{ config(
    enabled = var('sourcesystem') == 'netsuite',
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
            coalesce(tl.department, 0)
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
    {%endif%}
   
    COALESCE(l.NAME, 'Unknown') AS LOCATION_NAME,
    COALESCE(s.NAME, 'Unknown') AS SUBSIDIARY_NAME,
    COALESCE(a.FULLNAME, 'Unknown') AS ACCOUNT_NAME,
    COALESCE(c.NAME, 'Unknown') AS CLASS_NAME,
    COALESCE(d.FULLNAME, 'Unknown') AS DEPARTMENT_NAME,
    {%if company == 'wagway'%}
    COALESCE(ad.name, 'Unknown') AS ADJUSTMENT_NAME,
    {%endif%}
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
            coalesce(b.department, 0)
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
        {%endif%} 
        COALESCE(l.NAME, 'Unknown') AS LOCATION_NAME,
        COALESCE(s.NAME, 'Unknown') AS SUBSIDIARY_NAME,
        COALESCE(a.FULLNAME, 'Unknown') AS ACCOUNT_NAME,
        COALESCE(c.NAME, 'Unknown') AS CLASS_NAME,
        COALESCE(d.FULLNAME, 'Unknown') AS DEPARTMENT_NAME,
        {%if company == 'wagway'%}
        COALESCE(ad.name, 'Unknown')   AS ADJUSTMENT_NAME, 
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
SELECT DISTINCT  * ,
NULL AS METRIC_L1,
    NULL AS METRIC_L2,
    NULL AS METRIC_L3,
    NULL AS METRIC_L4,
    NULL AS METRIC_L5,
    NULL AS METRIC_L6,
    NULL AS CASHFLOW_L1,
    NULL AS CASHFLOW_L2,
    NULL AS CASHFLOW_L3,
    NULL AS IS_BS,
    NULL AS DEBT_MAPPING
    FROM combined