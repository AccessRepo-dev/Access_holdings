{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'subsidiary',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'SUBSIDIARY') }}
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(ID AS INT) AS ID,
        TRIM(NAME) AS NAME,
        TRIM(FULLNAME) AS FULLNAME,
        SPLIT_PART(FULLNAME, ':', 2) AS SUB_NAME2,
        SPLIT_PART(FULLNAME, ':', 3) AS SUB_NAME3,
        SPLIT_PART(FULLNAME, ':', 4) AS SUB_NAME4,
        SPLIT_PART(FULLNAME, ':', 5) AS SUB_NAME5,
        SPLIT_PART(FULLNAME, ':', 6) AS SUB_NAME6,
        TRY_CAST(PARENT AS INT) AS PARENT,
        TRY_CAST(CURRENCY AS INT) AS CURRENCY,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS ISINACTIVE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)
select
    *
from cleaned