{% set company = var('company', 'wagway') | lower %}
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
    from {{ get_raw_source(company, sourcesystem, 'ACCOUNT') }}
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
        TRIM(ACCTNUMBER) AS ACCTNUMBER,
        TRIM(FULLNAME) AS FULLNAME,
        case
            when POSITION(':' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, ':', 1)), '')
            when POSITION('-' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, '-', 1)), '')
            else TRIM(FULLNAME)
        end as MAIN_ACCOUNT_NAME,

        case
            when POSITION(':' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, ':', 2)), '')
            when POSITION('-' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, '-', 2)), '')
            else null
        end as ACCOUNT_NAME_SUBCATEGORY_1,

        case
            when POSITION(':' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, ':', 3)), '')
            when POSITION('-' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, '-', 3)), '')
            else null
        end as ACCOUNT_NAME_SUBCATEGORY_2,

        case
            when POSITION(':' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, ':', 4)), '')
            when POSITION('-' in FULLNAME) > 0 then NULLIF(TRIM(SPLIT_PART(FULLNAME, '-', 4)), '')
            else null
        end as ACCOUNT_NAME_SUBCATEGORY_3,

        TRIM(ACCTTYPE) AS ACCTTYPE,
        TRIM(DESCRIPTION) AS DESCRIPTION,
        TRIM(ACCOUNTSEARCHDISPLAYNAME) AS ACCOUNTSEARCHDISPLAYNAME,
        TRIM(DISPLAYNAMEWITHHIERARCHY) AS DISPLAYNAMEWITHHIERARCHY,
        TRY_CAST(PARENT AS INT) AS PARENT,
        TRIM(SUBSIDIARY) AS SUBSIDIARY,
        TRY_CAST(CLASS AS INT) AS CLASS,
        TRY_CAST(DEPARTMENT AS INT) AS DEPARTMENT,
        TRY_CAST(LOCATION AS INT) AS LOCATION,
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
