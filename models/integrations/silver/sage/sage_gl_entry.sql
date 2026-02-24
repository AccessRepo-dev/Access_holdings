{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage' and var('company', 'spotless') in ['spotless','amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_ENTRY_BKP') }}
    where lower(STATE) = 'posted' 
    {% if is_incremental() %}
        and  
        cast(WHENMODIFIED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    {% endif %}

),

cleaned as (

    SELECT
    
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    COALESCE(ACCOUNTKEY ,0) AS ACCOUNTKEY,
    TRY_CAST(ACCOUNTNO AS varchar ) AS ACCOUNTNO,
    TRIM(ACCOUNTTITLE) AS ACCOUNTTITLE,
    TRIM(BATCHNO) AS BATCHNO,
    TRIM(BATCHTITLE) AS BATCHTITLE,
    COALESCE(CLASSDIMKEY ,0) AS CLASSDIMKEY,
    TRIM(CLASSID) AS CLASSID,
    COALESCE(DEPARTMENTKEY ,0) AS DEPARTMENTKEY,
    TRY_CAST(ITEMDIMKEY AS INT) AS ITEMDIMKEY,
    TRIM(ITEMID) AS ITEMID,
    COALESCE(LOCATIONKEY ,0) AS LOCATIONKEY,
    TRIM(LOCATIONNAME) AS LOCATIONNAME,
    TRIM(STATE) AS STATE,
    TRY_CAST(LINE_NO AS INT) AS LINE_NO,
    TRY_CAST(TR_TYPE AS INT) AS TR_TYPE,
    COALESCE(PROJECTDIMKEY ,0) AS PROJECTDIMKEY,
    CAST(VENDORDIMKEY AS INT) AS VENDORDIMKEY,


    AMOUNT,
    TRX_AMOUNT, 
    TRIM(CURRENCY) AS CURRENCY,
    TRY_CAST(EXCHANGE_RATE AS INT) AS EXCHANGE_RATE,
   
    -- Dates
    CAST(BATCH_DATE AS DATE) AS BATCH_DATE,
    CAST(ENTRY_DATE AS DATE) AS ENTRY_DATE,
   
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

  
    -- Silver Load Metadata
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data

)

select *
from cleaned
