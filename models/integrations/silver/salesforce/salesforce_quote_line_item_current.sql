{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    alias = sourcesystem ~ '_QUOTE_LINE_ITEM',
    schema = 'silver',
    unique_key = 'ID_DATE_KEY',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns'
) }}


with raw as 
(
select concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ sf_canonical_quote_line_item(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
from {{ ref('salesforce_quote_line_item_snapshot') }}

    {% if is_incremental() %}
    where 
        (cast(LAST_MODIFIED_DATE as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)) from {{ this }})
    OR 
        (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% else %}
    where 1=1
    --DBT_VALID_TO is null
    {% endif %}
),

cleaned as (
    select ID_DATE_KEY AS ID_DATE_KEY,
    TRIM(QUOTE_LINE_ITEM_ID) AS QUOTE_LINE_ITEM_ID,
    QUOTE_ID AS QUOTE_ID,
    TRIM(PRODUCT_ID) AS PRODUCT_ID,
    QUANTITY AS QUANTITY,
    CAST(UNIT_PRICE AS NUMBER) AS UNIT_PRICE,
    SERVICE_DATE AS SERVICE_DATE,
    DISCOUNT AS DISCOUNT,
    CAST(TOTAL_PRICE AS NUMBER) AS TOTAL_PRICE,
    CREATED_DATE AS CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    IS_ACTIVE AS IS_ACTIVE
from raw
)
select * from cleaned