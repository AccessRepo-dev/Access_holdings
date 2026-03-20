{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    alias = sourcesystem ~ '_RECORD_TYPE',
    schema = 'silver',
    unique_key = 'ID_DATE_KEY',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select 
    concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ sf_canonical_record_type(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
from {{ ref('salesforce_record_type_snapshot') }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
),

cleaned as (
select ID_DATE_KEY AS ID_DATE_KEY,
    ID AS ID,
    NAME AS NAME,
    DEVELOPER_NAME AS DEVELOPER_NAME,
    NAMESPACE_PREFIX AS NAMESPACE_PREFIX,
    DESCRIPTION AS DESCRIPTION,
    BUSINESS_PROCESS_ID AS BUSINESS_PROCESS_ID,
    SOBJECT_TYPE AS SOBJECT_TYPE,
    RECORD_TYPE_IS_ACTIVE AS RECORD_TYPE_IS_ACTIVE,
    CREATED_BY_ID AS CREATED_BY_ID,
    CREATED_DATE AS CREATED_DATE,
    LAST_MODIFIED_BY_ID AS LAST_MODIFIED_BY_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    SYSTEM_MODSTAMP AS SYSTEM_MODSTAMP,
    IS_PERSON_TYPE AS IS_PERSON_TYPE,
    _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    IS_ACTIVE AS IS_ACTIVE
from raw
)

select * from cleaned