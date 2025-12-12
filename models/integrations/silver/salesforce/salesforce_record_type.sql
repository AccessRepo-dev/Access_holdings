{% set company = var('company','zeus') %}
{% set sourcesystem = var('sourcesystem','salesforce') %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce') }}
{{ config(enabled = var('company','zeus') == 'zeus') }}

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
        (cast(LAST_MODIFIED_DATE as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    OR 
        (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
{% else %}
    where 1=1
{% endif %}
),

cleaned as (
select 
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
    ID,
    NAME,
    DEVELOPER_NAME,
    NAMESPACE_PREFIX,
    DESCRIPTION,
    BUSINESS_PROCESS_ID,
    SOBJECT_TYPE,
    IS_ACTIVE AS RECORD_TYPE_IS_ACTIVE,
    CREATED_BY_ID,
    CREATED_DATE,
    LAST_MODIFIED_BY_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    SYSTEM_MODSTAMP,
    IS_PERSON_TYPE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

select * from cleaned