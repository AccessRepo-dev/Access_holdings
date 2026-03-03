{% set company = var("company", "amh") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot", "hubspot_pawville"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_LINE_ITEM',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select CONCAT(ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_line_item(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    from {{ ref('hubspot_line_item_snapshot') }}
    
    {% if is_incremental() %}
        where 
            (_FIVETRAN_SYNCED > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01')) from {{ this }})
        OR 
            (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% else %}
        where 1=1
    {% endif %}
),

cleaned as (
    select ID_DATE_KEY AS ID_DATE_KEY, 
            ID AS ID,
            PRODUCT_ID AS PRODUCT_ID,
            PROPERTY_INVOICE_ITEM_ID AS PROPERTY_INVOICE_ITEM_ID,
            PROPERTY_DESCRIPTION AS PROPERTY_DESCRIPTION,
            PROPERTY_NAME AS PROPERTY_NAME,
            PROPERTY_AMOUNT AS PROPERTY_AMOUNT,
            PROPERTY_QUANTITY AS PROPERTY_QUANTITY,
            PROPERTY_HS_LINE_ITEM_CURRENCY_CODE AS PROPERTY_HS_LINE_ITEM_CURRENCY_CODE,
            PROPERTY_HS_MARGIN_ACV AS PROPERTY_HS_MARGIN_ACV,
            PROPERTY_HS_MARGIN_ARR AS PROPERTY_HS_MARGIN_ARR,
            PROPERTY_HS_MARGIN_MRR AS PROPERTY_HS_MARGIN_MRR,
            PROPERTY_HS_MARGIN_TCV AS PROPERTY_HS_MARGIN_TCV,
            PROPERTY_HS_PRICING_MODEL AS PROPERTY_HS_PRICING_MODEL,
            PROPERTY_HS_LASTMODIFIEDDATE AS PROPERTY_HS_LASTMODIFIEDDATE,
            _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
            SILVER_LOAD_DATE::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
            CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
            IS_ACTIVE AS IS_ACTIVE
    from source
)

select * from cleaned
