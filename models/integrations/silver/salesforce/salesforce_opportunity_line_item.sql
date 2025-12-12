{% set company = var('company','zeus') %}
{% set sourcesystem = var('sourcesystem','salesforce') %}
{{ config(enabled = var('sourcesystem', 'salesforce') == 'salesforce' and var('company','zeus') == 'zeus') }}

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
from {{ source_snapshot_schema(company, 'SALESFORCE_OPPORTUNITY_LINE_ITEM') }}
    {% if is_incremental()%}
    where 
        (cast(LAST_MODIFIED_DATE as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    OR 
        (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% endif %}
),


cleaned as 
(
select CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
    ID,
    OPPORTUNITY_ID,
    SORT_ORDER,
    PRICEBOOK_ENTRY_ID,
    PRODUCT_2_ID,
    PRODUCT_CODE,
    NAME,
    QUANTITY,
    DISCOUNT,
    TOTAL_PRICE,
    UNIT_PRICE,
    LIST_PRICE,
    SERVICE_DATE,
    DESCRIPTION,
    CREATED_DATE,
    CREATED_BY_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    LAST_MODIFIED_BY_ID,
    SYSTEM_MODSTAMP,
    IS_DELETED,
    LAST_VIEWED_DATE,
    LAST_REFERENCED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
from raw
)

select * from cleaned