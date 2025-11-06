{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'gl_entry',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'GL_ENTRY') }}
    where lower(STATE) = 'posted' 
    {% if is_incremental() %}
        and WHENMODIFIED > (
            select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
    {% endif %}

),

cleaned as (

    SELECT
    
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRY_CAST(ACCOUNTKEY AS INT) AS ACCOUNTKEY,
    TRY_CAST(ACCOUNTNO AS varchar ) AS ACCOUNTNO,
    TRIM(ACCOUNTTITLE) AS ACCOUNTTITLE,
    TRIM(BATCHNO) AS BATCHNO,
    TRIM(BATCHTITLE) AS BATCHTITLE,
    TRY_CAST(CLASSDIMKEY AS INT) AS CLASSDIMKEY,
    TRIM(CLASSID) AS CLASSID,
    TRY_CAST(DEPARTMENTKEY AS INT) AS DEPARTMENTKEY,
    TRY_CAST(ITEMDIMKEY AS INT) AS ITEMDIMKEY,
    TRIM(ITEMID) AS ITEMID,
    TRY_CAST(LOCATIONKEY AS INT) AS LOCATIONKEY,
    TRIM(LOCATIONNAME) AS LOCATIONNAME,
    TRIM(STATE) AS STATE,
    TRY_CAST(LINE_NO AS INT) AS LINE_NO,
    TRY_CAST(TR_TYPE AS INT) AS TR_TYPE,
    TRY_CAST(PROJECTDIMKEY AS INT) AS PROJECTDIMKEY,
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
