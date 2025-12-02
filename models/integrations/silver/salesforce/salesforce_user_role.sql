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
from {{ source_snapshot_schema(company, 'SALESFORCE_USER_ROLE') }}
{% if is_incremental() %}
    where 
        (cast(LAST_MODIFIED_DATE as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    OR 
        (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
{% else %}
    where 1=1
    --DBT_VALID_TO is null
{% endif %}
),

cleaned as (
select
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
    TRIM(ID) AS USER_ROLE_ID,
    TRIM(NAME) AS ROLE_NAME,
    TRIM(DEVELOPER_NAME) AS DEVELOPER_NAME,
    TRIM(PARENT_ROLE_ID) AS PARENT_ROLE_ID,
    TRIM(ROLLUP_DESCRIPTION) AS ROLLUP_DESCRIPTION,
    TRIM(FORECAST_USER_ID) AS FORECAST_USER_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

select * from cleaned
