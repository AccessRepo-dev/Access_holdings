{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~ '_LEAD',
    schema = 'silver',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ sf_canonical_lead(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
from {{ ref('salesforce_lead_snapshot') }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
),


cleaned as 
(
select
    ID_DATE_KEY AS ID_DATE_KEY,
    TRIM(LEAD_ID) AS LEAD_ID,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(COMPANY) AS COMPANY,
    TRIM(FIRST_NAME) AS FIRST_NAME,
    TRIM(LAST_NAME) AS LAST_NAME,
    TRIM(SALUTATION) AS SALUTATION,
    TRIM(TITLE) AS TITLE,
    EMAIL AS EMAIL,
    PHONE AS PHONE,
    MOBILE_PHONE AS MOBILE_PHONE,
    WEBSITE AS WEBSITE,
    TRIM(LEAD_SOURCE) AS LEAD_SOURCE,
    TRIM(STATUS) AS STATUS,
    TRIM(RATING) AS RATING,
    TRIM(INDUSTRY) AS INDUSTRY,
    TRY_CAST(NUMBER_OF_EMPLOYEES AS INT) AS NUMBER_OF_EMPLOYEES,
    TRIM(STREET) AS STREET,
    TRIM(CITY) AS CITY,
    TRIM(STATE) AS STATE,
    TRY_CAST(POSTAL_CODE AS INT) AS POSTAL_CODE,
    TRIM(COUNTRY) AS COUNTRY,
    CONVERTED_DATE AS CONVERTED_DATE,
    TRIM(CONVERTED_ACCOUNT_ID) AS CONVERTED_ACCOUNT_ID,
    TRIM(CONVERTED_CONTACT_ID) AS CONVERTED_CONTACT_ID,
    TRIM(CONVERTED_OPPORTUNITY_ID) AS CONVERTED_OPPORTUNITY_ID,
    IS_CONVERTED AS IS_CONVERTED,
    CREATED_DATE AS CREATED_DATE,
    TRIM(CREATED_BY_ID) AS CREATED_BY_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TRIM(LAST_MODIFIED_BY_ID) AS LAST_MODIFIED_BY_ID,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    Is_Active
from raw
)

select * from cleaned