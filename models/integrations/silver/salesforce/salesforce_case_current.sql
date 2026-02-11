{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database=get_target_database(var('company')),
    alias = sourcesystem ~ '_CASE',
    materialized = 'incremental',
    schema = 'silver',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select *
from {{ ref('salesforce_case_snapshot') }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
),


cleaned as 
(
    select
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
    TRIM(ID) AS CASE_ID,
    ACCOUNT_ID,
    CONTACT_ID,
    OWNER_ID,
    STATUS,
    ORIGIN,
    REASON,
    SUBJECT,
    DESCRIPTION,
    IS_CLOSED,
    CAST(CLOSED_DATE AS TIMESTAMP_NTZ) AS CLOSED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
     _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from raw
)

select * from cleaned
