{% set company = var('company', 'playfly') | lower %}
{% set sourcesystem  = var('sourcesystem', 'netsuite') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'NKEY'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'TRANSACTIONADDRESSMAPPINGADDRESS') }}
    {% if is_incremental() %}
    where 
        cast(LASTMODIFIEDDATE as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(NKEY AS INT) AS NKEY,
        TRIM(ADDR1) AS ADDR1,
        TRIM(ADDR2) AS ADDR2,
        TRIM(ADDR3) AS ADDR3,
        TRIM(ADDRESSEE) AS ADDRESSEE,
        TRIM(ADDRPHONE) AS ADDRPHONE,
        TRIM(ADDRTEXT) AS ADDRTEXT,
        TRIM(ATTENTION) AS ATTENTION,
        TRIM(CITY) AS CITY,
        TRIM(COUNTRY) AS COUNTRY,
        TRIM(DROPDOWNSTATE) AS DROPDOWNSTATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        TRIM(OVERRIDE) AS OVERRIDE,
        TRY_CAST(RECORDOWNER AS INT) AS RECORDOWNER,
        TRIM(STATE) AS STATE,
        TRIM(ZIP) AS ZIP,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned