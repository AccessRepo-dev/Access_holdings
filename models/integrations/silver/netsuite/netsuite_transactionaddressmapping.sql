{% set company = var('company', 'playfly') | lower %}
{% set sourcesystem  = var('sourcesystem', 'netsuite') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'TRANSACTIONADDRESSMAPPING') }}
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
        TRY_CAST(ID AS INT) AS ID,
        TRY_CAST(ADDRESS AS INT) AS ADDRESS,
        TRIM(ADDRESSTYPE) AS ADDRESSTYPE,
        TRY_CAST(CREATEDBY AS INT) AS CREATEDBY,
        CAST(CREATEDDATE AS TIMESTAMP_NTZ) AS CREATEDDATE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        TRY_CAST(TRANSACTION AS INT) AS TRANSACTION,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned