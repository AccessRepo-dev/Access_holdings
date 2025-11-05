{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'id',
    strategy = 'timestamp',
    updated_at = 'LAST_MODIFIED_DATE',
    invalidate_hard_deletes = True
) }}


with raw as 
(
select *

from {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }}
where DBT_VALID_TO is null
),

cleaned as (
    select
    TRIM(ID) AS ID,
    TRIM(NAME) AS NAME,
    TRY_CAST(PARENT_ID AS INT) AS PARENT_ID,
    TRIM(INDUSTRY) AS INDUSTRY,
    TRY_CAST(NUMBER_OF_EMPLOYEES AS INT) AS NUMBER_OF_EMPLOYEES,
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
    TRIM(DESCRIPTION) AS DESCRIPTION
    from raw
)

select * from cleaned