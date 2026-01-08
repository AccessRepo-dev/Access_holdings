{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database=get_target_database(var('company')),
    alias = sourcesystem ~ '_CONTACT',
    materialized = 'incremental',
    schema = 'silver',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select *
from {{ ref('salesforce_contact_snapshot') }}
    {% if is_incremental()%}
    where 
        (cast(LAST_MODIFIED_DATE as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    OR 
        (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
{% else %} 
    where 1 = 1
{% endif %}
),


cleaned as 
(
select
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
    TRIM(ID) AS CONTACT_ID,
    ACCOUNT_ID,
    TRIM(NAME) AS NAME,
    TRIM(FIRST_NAME) AS FIRST_NAME,
    TRIM(LAST_NAME) AS LAST_NAME,
    TRIM(SALUTATION) AS SALUTATION,
    TRIM(TITLE) AS TITLE,
    TRIM(DEPARTMENT) AS DEPARTMENT,
    EMAIL,
    PHONE,
    MOBILE_PHONE,
    TRIM(MAILING_STREET) AS MAILING_STREET,
    TRIM(MAILING_CITY) AS MAILING_CITY,
    TRIM(MAILING_STATE) AS MAILING_STATE,
    TRY_CAST(MAILING_POSTAL_CODE AS INT) AS MAILING_POSTAL_CODE,
    TRIM(MAILING_COUNTRY) AS MAILING_COUNTRY,
    LEAD_SOURCE,
    TRIM(OWNER_ID) AS OWNER_ID,
    CREATED_DATE,
    TRIM(CREATED_BY_ID) AS CREATED_BY_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TRIM(LAST_MODIFIED_BY_ID) AS LAST_MODIFIED_BY_ID,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

select * from cleaned