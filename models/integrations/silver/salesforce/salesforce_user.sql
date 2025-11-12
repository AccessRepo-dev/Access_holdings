{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'ID_DATE_KEY',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select *
from {{ source_snapshot_schema(company, 'SALESFORCE_USER') }}
{% if is_incremental() %}
    where 
        LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
            from {{ this }})
        and DBT_VALID_TO is null
{% else %}
    where 1=1
    --DBT_VALID_TO is null
{% endif %}
    
),

cleaned as (
select
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) as ID_DATE_KEY,
    TRIM(ID) AS ID,
    TRIM(USERNAME) AS USERNAME,
    TRIM(EMAIL) AS EMAIL,
    TRIM(ALIAS) AS ALIAS,
    TRIM(FIRST_NAME) AS FIRST_NAME,
    TRIM(LAST_NAME) AS LAST_NAME,
    IS_ACTIVE,
    TRIM(USER_ROLE_ID) AS USER_ROLE_ID,
    TRIM(PROFILE_ID) AS PROFILE_ID,
    TRIM(TITLE) AS TITLE,
    TRIM(DEPARTMENT) AS DEPARTMENT,
    TRIM(MANAGER_ID) AS MANAGER_ID,
    CREATED_DATE,
    LAST_LOGIN_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TIME_ZONE_SID_KEY,
    LOCALE_SID_KEY,
    TRIM(LANGUAGE_LOCALE_KEY) AS LANGUAGE_LOCALE_KEY,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO
from raw
)

select * from cleaned