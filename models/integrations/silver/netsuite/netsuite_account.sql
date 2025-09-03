{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ACCOUNT_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ACCOUNT') }}
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
        TRY_CAST(ID AS INT) AS ACCOUNT_ID,
        TRIM(ACCTNUMBER) AS ACCOUNT_NUMBER,
        TRIM(FULLNAME) AS ACCOUNT_NAME,
        TRIM(SPLIT_PART(FULLNAME, ':', 1)) AS ACCOUNT_LEVEL_1,
        TRIM(SPLIT_PART(FULLNAME, ':', 2)) AS ACCOUNT_LEVEL_2,
        TRIM(SPLIT_PART(FULLNAME, ':', 3)) AS ACCOUNT_LEVEL_3,
        TRIM(ACCTTYPE) AS ACCOUNT_TYPE,
        TRIM(DESCRIPTION) AS ACCOUNT_DESCRIPTION,
        TRIM(ACCOUNTSEARCHDISPLAYNAME) AS DISPLAY_NAME,
        TRIM(DISPLAYNAMEWITHHIERARCHY) AS DISPLAY_NAME_WITH_HIERARCHY,
        TRY_CAST(PARENT AS INT) AS PARENT_ID,
        SUBSIDIARY AS SUBSIDIARY_ID,
        TRY_CAST(CLASS AS INT) AS CLASS_ID,
        TRY_CAST(DEPARTMENT AS INT) AS DEPARTMENT_ID,
        TRY_CAST(LOCATION AS INT) AS LOCATION_ID,
        TRY_CAST(CURRENCY AS INT) AS CURRENCY_ID,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS IS_INACTIVE,
        CAST(LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE 
    from source_data
)

select 
    *
from cleaned
