{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'POSTING_PERIOD_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ACCOUNTINGPERIOD') }}
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select 
        TRY_CAST(ID AS INT) AS POSTING_PERIOD_ID,
        TRIM(PERIODNAME) AS PERIOD_NAME,
        TRY_CAST("YEAR" AS INT) AS YEAR,
        CAST(STARTDATE AS TIMESTAMP_NTZ) AS START_DATE,
        CAST(ENDDATE AS TIMESTAMP_NTZ) AS END_DATE,
        CAST(CLOSEDONDATE AS DATE) AS CLOSED_ON_DATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select 
    *
from cleaned
