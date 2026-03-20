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
select  concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ sf_canonical_case(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
from {{ ref('salesforce_case_snapshot') }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
),


cleaned as 
(
    select
    ID_DATE_KEY as ID_DATE_KEY,
    TRIM(CASE_ID) AS CASE_ID,
    ACCOUNT_ID as ACCOUNT_ID,
    CONTACT_ID as CONTACT_ID,
    OWNER_ID as OWNER_ID,
    STATUS as STATUS,
    ORIGIN as ORIGIN,
    REASON as REASON,
    SUBJECT as SUBJECT,
    DESCRIPTION as DESCRIPTION,
    IS_CLOSED as IS_CLOSED,
    CAST(CLOSED_DATE AS TIMESTAMP_NTZ) AS CLOSED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    SILVER_LOAD_DATE AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    Is_Active AS Is_Active
    from raw
)

select * from cleaned
