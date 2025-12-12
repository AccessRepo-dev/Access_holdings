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

from {{ source_snapshot_schema(company, 'SALESFORCE_QUOTE') }}

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
    TRIM(ID) AS QUOTE_ID,
    TRIM(OPPORTUNITY_ID) AS OPPORTUNITY_ID,
    TRIM(ACCOUNT_ID) AS ACCOUNT_ID,
    TRIM(STATUS) AS STATUS,
    TRY_CAST(QUOTE_NUMBER AS INT) AS QUOTE_NUMBER,
    TRIM(NAME) AS NAME,
    EXPIRATION_DATE,
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
    DISCOUNT,
    CAST(GRAND_TOTAL AS NUMBER) AS GRAND_TOTAL,
    CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(PRICEBOOK_2_ID) AS PRICEBOOK_2_ID,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

select * from cleaned