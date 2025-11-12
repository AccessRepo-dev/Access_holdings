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
select 
    *
from {{ source_snapshot_schema(company, 'SALESFORCE_RECORD_TYPE') }}
{% if is_incremental() %}
    where 
        LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
            from {{ this }})
        and 1=1
        --DBT_VALID_TO is null
{% else %}
    where 1=1
    --DBT_VALID_TO is null
{% endif %}
),

cleaned as (
select 
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) as ID_DATE_KEY,
    ID,
    NAME,
    DEVELOPER_NAME,
    NAMESPACE_PREFIX,
    DESCRIPTION,
    BUSINESS_PROCESS_ID,
    SOBJECT_TYPE,
    IS_ACTIVE
    ,CREATED_BY_ID,
    CREATED_DATE,
    LAST_MODIFIED_BY_ID,
    LAST_MODIFIED_DATE,
    SYSTEM_MODSTAMP,
    IS_PERSON_TYPE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO
from raw
)

select * from cleaned