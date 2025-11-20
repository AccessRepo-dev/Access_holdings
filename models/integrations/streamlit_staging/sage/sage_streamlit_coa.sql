{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{% set src = var('company') ~ '_' ~ var('sourcesystem') ~ '_raw'%}



{{ config(
    enabled = var('sourcesystem') == 'sage',
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
    COALESCE(e.CLASSDIMKEY, 0) AS CLASS_ID,
    COALESCE(e.LOCATIONKEY, 0) AS LOCATION_ID,
   COALESCE(e.PROJECTDIMKEY,0) AS PROJECT_ID,
    COALESCE(e.DEPARTMENTKEY, 0) AS DEPARTMENT_ID,
    
    COALESCE(e.LOCATIONNAME, 'Unknown') AS LOCATION_NAME,
    COALESCE(e.PROJECTNAME, 'Unknown') AS PROJECT_NAME,
    COALESCE(e.ACCOUNTTITLE, 'Unknown') AS ACCOUNT_NAME,
    COALESCE(e.CLASSNAME, 'Unknown') AS CLASS_NAME,
    COALESCE(e.DEPARTMENTTITLE, 'Unknown') AS DEPARTMENT_NAME,

    CURRENT_TIMESTAMP AS DATA_LOADED_AT 


FROM {{ source(src, 'GL_ENTRY') }} e

{% if is_incremental() %}
    where COA_ID not in (
        select COA_ID
        from {{ this }}
    )
{% endif %}
),
budget as (
    SELECT
    DISTINCT

    HASH(COALESCE(e.ACCOUNTKEY,0), COALESCE(e.LOCATIONKEY,0),COALESCE(e.DEPTKEY,0),COALESCE(e.PROJECTDIMKEY,0),COALESCE(e.CLASSDIMKEY,0)) AS COA_ID,
    
    COALESCE(e.ACCOUNTKEY, 0) AS ACCOUNT_ID,
    COALESCE(e.CLASSDIMKEY, 0) AS CLASS_ID,
    COALESCE(e.LOCATIONKEY, 0) AS LOCATION_ID,
   COALESCE(e.PROJECTDIMKEY,0) AS PROJECT_ID,
    COALESCE(e.DEPTKEY, 0) AS DEPARTMENT_ID,
    
    COALESCE(e.LOCATIONTITLE, 'Unknown') AS LOCATION_NAME,
    COALESCE(e.PROJECTNAME, 'Unknown') AS PROJECT_NAME,
    COALESCE(e.ACCTTITLE, 'Unknown') AS ACCOUNT_NAME,
    COALESCE(e.CLASSNAME, 'Unknown') AS CLASS_NAME,
    COALESCE(e.DEPTITLE, 'Unknown') AS DEPARTMENT_NAME,

    CURRENT_TIMESTAMP AS DATA_LOADED_AT 

    FROM {{ source(src, 'GL_BUDGET_ITEM') }} e
      {% if is_incremental() %}
    where COA_ID not in (
        select COA_ID
        from {{ this }}
    )
    {% endif %}
),
combined as (
select * from budget
UNION ALL 
SELECT * FROM transaction
) 
SELECT  * ,
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