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
select *

from {{ source_snapshot_schema(company, 'SALESFORCE_ACCOUNT') }}

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
    ID AS ACCOUNT_ID,
    TRIM(ACCOUNT_SOURCE) as ACCOUNT_SOURCE, 
    EXTERNAL_ACCOUNT_ID_C AS EXTERNAL_ACCOUNT_ID,
    TRIM(NAME) AS NAME,
    TRIM(TYPE) AS TYPE,
    PARENT_ID AS PARENT_ID,
    TRIM(PARENT_COMPANY_ZM_C) AS PARENT_COMPANY,
    TRIM(INDUSTRY) AS INDUSTRY,
    TRY_CAST(NUMBER_OF_EMPLOYEES AS INT) AS NUMBER_OF_EMPLOYEES,
    CAST(REVENUE_C AS NUMBER) AS ANNUAL_REVENUE,
    TRIM(WEBSITE) AS WEBSITE,
    TRIM(BILLING_STREET) AS BILLING_STREET,
    TRIM(BILLING_CITY) AS BILLING_CITY,
    TRIM(BILLING_STATE) AS BILLING_STATE,
    TRY_CAST(BILLING_POSTAL_CODE AS INT) AS BILLING_POSTAL_CODE,
    TRIM(BILLING_COUNTRY) AS BILLING_COUNTRY,
    TRIM(SHIPPING_STREET) AS SHIPPING_STREET,
    TRIM(SHIPPING_CITY) AS SHIPPING_CITY,
    TRIM(SHIPPING_STATE) AS SHIPPING_STATE,
    TRY_CAST(SHIPPING_POSTAL_CODE AS INT) AS SHIPPING_POSTAL_CODE,
    TRIM(SHIPPING_COUNTRY) AS SHIPPING_COUNTRY,
    TRIM(OWNER_ID) AS OWNER_ID,
    CREATED_DATE,
    CREATED_BY_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TRIM(LAST_MODIFIED_BY_ID) AS LAST_MODIFIED_BY_ID,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from raw
)

select * from cleaned