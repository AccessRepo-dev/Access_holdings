{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{% set src = var('company') ~ '_' ~ var('sourcesystem') ~ '_raw'%}



{{ config(
    enabled = var('sourcesystem') == 'sage',
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
                COALESCE(a.ACCOUNTTITLE, 'Unknown') AS ACCOUNT_NAME,
                COALESCE(c.NAME, 'Unknown')          AS CLASS_NAME,
                COALESCE(d.TITLE, 'Unknown')         AS DEPARTMENT_NAME,
                COALESCE(l.NAME, 'Unknown')          AS LOCATION_NAME,
                COALESCE(p.NAME, 'Unknown')          AS PROJECT_NAME

            FROM (
                SELECT DISTINCT COA_ID, ACCOUNT_ID, CLASS_ID, DEPARTMENT_ID, LOCATION_ID, PROJECT_ID
                FROM {{ this }}
            ) t

            LEFT JOIN (
                SELECT DISTINCT ACCOUNTKEY, ACCOUNTTITLE
                FROM {{ source(var('company') ~ '_' ~ var('sourcesystem') ~ '_raw', 'GL_ENTRY') }}
            ) a ON a.ACCOUNTKEY = t.ACCOUNT_ID
            LEFT JOIN {{ source(var('company') ~ '_' ~ var('sourcesystem') ~ '_raw', 'CLASS') }} c
                ON c.RECORDNO = t.CLASS_ID
            LEFT JOIN {{ source(var('company') ~ '_' ~ var('sourcesystem') ~ '_raw', 'DEPARTMENT') }} d
                ON d.RECORDNO = t.DEPARTMENT_ID
            LEFT JOIN {{ source(var('company') ~ '_' ~ var('sourcesystem') ~ '_raw', 'LOCATION') }} l
                ON l.RECORDNO = t.LOCATION_ID
            LEFT JOIN {{ source(var('company') ~ '_' ~ var('sourcesystem') ~ '_raw', 'PROJECT') }} p
                ON p.RECORDNO = t.PROJECT_ID

        ) src ON tgt.COA_ID = src.COA_ID

        WHEN MATCHED AND NOT (
            EQUAL_NULL(tgt.ACCOUNT_NAME,  src.ACCOUNT_NAME)  AND
            EQUAL_NULL(tgt.CLASS_NAME,    src.CLASS_NAME)     AND
            EQUAL_NULL(tgt.DEPARTMENT_NAME, src.DEPARTMENT_NAME) AND
            EQUAL_NULL(tgt.LOCATION_NAME, src.LOCATION_NAME) AND
            EQUAL_NULL(tgt.PROJECT_NAME,  src.PROJECT_NAME)
        )
        THEN UPDATE SET
            tgt.ACCOUNT_NAME    = src.ACCOUNT_NAME,
            tgt.CLASS_NAME      = src.CLASS_NAME,
            tgt.DEPARTMENT_NAME = src.DEPARTMENT_NAME,
            tgt.LOCATION_NAME   = src.LOCATION_NAME,
            tgt.PROJECT_NAME    = src.PROJECT_NAME
        ;
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

    HASH(COALESCE(e.ACCOUNTKEY,0), COALESCE(e.LOCATIONKEY,0),COALESCE(e.DEPARTMENTKEY,0),COALESCE(e.PROJECTDIMKEY,0),COALESCE(e.CLASSDIMKEY,0)) AS COA_ID,
    COALESCE(e.ACCOUNTKEY, 0) AS ACCOUNT_ID,
    COALESCE(cast(e.ACCOUNTNO as varchar), 'Unknown') AS ACCOUNT_NUMBER,
    COALESCE(e.CLASSDIMKEY, 0) AS CLASS_ID,
    COALESCE(e.LOCATIONKEY, 0) AS LOCATION_ID,
    COALESCE(e.PROJECTDIMKEY,0) AS PROJECT_ID,
    COALESCE(e.DEPARTMENTKEY, 0) AS DEPARTMENT_ID,
    COALESCE(e.ACCOUNTTITLE, 'Unknown') AS ACCOUNT_NAME,
    --COALESCE(e.DEPARTMENTTITLE, 'Unknown') AS DEPARTMENT_NAME,
  
    CURRENT_TIMESTAMP AS DATA_LOADED_AT 


FROM {{ source(src, 'GL_ENTRY') }} e

{% if company | lower  == 'amh' %}
    WHERE e.RECORDNO NOT IN 
        (select distinct GLENTRYKEY 
        from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_GL_DETAIL') }}
        WHERE SYMBOL = 'QB_HISTORY' and 
            batch_date between '2022-01-01' and '2022-08-31'
        )
{% elif company | lower  == 'spotless' %}
    WHERE e.BATCHTITLE not in ('VIE Depreciation & Amortization','record VIE transactions') 
    AND 
    e.RECORDNO NOT IN 
        (select 
            distinct GLENTRYKEY 
            from {{ get_silver_source(company, (var('sourcesystem') | upper) ~ '_GL_DETAIL') }}
            WHERE SYMBOL IN ('DBJ','DCJ','GAAP YE ADJS','MAT','PROAJ','PAJ')
        )
{% endif %}

),
budget as (
    SELECT
    DISTINCT

    HASH(COALESCE(e.ACCOUNTKEY,0), COALESCE(e.LOCATIONKEY,0),COALESCE(e.DEPTKEY,0),COALESCE(e.PROJECTDIMKEY,0),COALESCE(e.CLASSDIMKEY,0)) AS COA_ID,
    
    COALESCE(e.ACCOUNTKEY, 0) AS ACCOUNT_ID,
    COALESCE(CAST(e.ACCT_NO AS VARCHAR), 'Unknown') AS ACCOUNT_NUMBER,
    COALESCE(e.CLASSDIMKEY, 0) AS CLASS_ID,
    COALESCE(e.LOCATIONKEY, 0) AS LOCATION_ID,
   COALESCE(e.PROJECTDIMKEY,0) AS PROJECT_ID,
    COALESCE(e.DEPTKEY, 0) AS DEPARTMENT_ID,
    

     COALESCE(e.ACCTTITLE, 'Unknown') AS ACCOUNT_NAME,
   --COALESCE(e.DEPTITLE, 'Unknown') AS DEPARTMENT_NAME,

    CURRENT_TIMESTAMP AS DATA_LOADED_AT
    FROM {{ source(src, 'GL_BUDGET_ITEM') }} e

),
combined as (
select * from budget
UNION  
SELECT * FROM transaction
) 

{%if company == 'spotless'%}
SELECT DISTINCT  a.*,
    COALESCE(l.name, 'Unknown') AS LOCATION_NAME,
    COALESCE(p.NAME, 'Unknown') AS PROJECT_NAME,
    --COALESCE(e.ACCTTITLE, 'Unknown') AS ACCOUNT_NAME,
    COALESCE(c.name, 'Unknown') AS CLASS_NAME,
    COALESCE(d.TITLE, 'Unknown') AS DEPARTMENT_NAME,
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
    LEFT JOIN {{this}} b ON a.ACCOUNT_ID = b.ACCOUNT_ID AND a.LOCATION_ID = b.LOCATION_ID AND a.CLASS_ID = b.CLASS_ID AND METRIC_L1 IS NOT NULL 

{%else%}
SELECT DISTINCT  a.* ,
COALESCE(l.name, 'Unknown') AS LOCATION_NAME,
    COALESCE(p.NAME, 'Unknown') AS PROJECT_NAME,
    --COALESCE(e.ACCTTITLE, 'Unknown') AS ACCOUNT_NAME,
    COALESCE(c.name, 'Unknown') AS CLASS_NAME,
    COALESCE(d.TITLE, 'Unknown') AS DEPARTMENT_NAME,
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
    NULL AS DEBT_MAPPING,
    NULL AS LAST_UPDATED_BY,
    NULL AS LAST_UPDATED_AT
    FROM combined a
{%endif%} 
LEFT JOIN  {{ source(src, 'CLASS') }} c ON c.RECORDNO = a.CLASS_ID
LEFT JOIN {{ source(src, 'DEPARTMENT') }}  d ON d.RECORDNO = a.DEPARTMENT_ID
LEFT JOIN {{ source(src, 'LOCATION') }}  l ON l.RECORDNO = a.LOCATION_ID
LEFT JOIN {{ source(src, 'PROJECT') }}  p ON p.RECORDNO = a.PROJECT_ID
{% if is_incremental() %}
    where a.COA_ID not in (
        select COA_ID
        from {{ this }}
    )
{%endif%} 
