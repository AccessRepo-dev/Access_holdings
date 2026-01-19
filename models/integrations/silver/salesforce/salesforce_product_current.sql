{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    alias = sourcesystem ~ '_PRODUCT',
    schema = 'silver',
    unique_key = 'ID_DATE_KEY',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select *
from {{ ref('salesforce_product_2_snapshot') }}
{% if is_incremental() %}
    where 
        (cast(LAST_MODIFIED_DATE as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    OR 
        (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))

{% else %}
    where 1=1

{% endif %}
    
),


cleaned as 
(
select
    CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
    ID AS PRODUCT_ID,
    TRIM(NAME) AS NAME,
    TRIM(PRODUCT_CODE) AS PRODUCT_CODE,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    FAMILY,
    IS_ACTIVE AS PRODUCT_IS_ACTIVE,
    CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    QUANTITY_UNIT_OF_MEASURE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

select * from cleaned