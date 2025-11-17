{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot','hubspot_pawville'] and var('company') | lower in ['wagway', 'playfly','amh'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_LINE_ITEM',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_LINE_ITEM') }}
    
    {% if is_incremental() %}
        where 
            _FIVETRAN_SYNCED > (
                select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'))
                from {{ this }}
            )
            and 1=1
    {% else %}
        where 1=1
    {% endif %}
),

cleaned as (
    select
        CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY, 
        ID,
        PRODUCT_ID,
        {% if company | lower in ['wagway']%}
            PROPERTY_INVOICE_ITEM_ID,
        {%else%}
            CAST(NULL AS INT) AS PROPERTY_INVOICE_ITEM_ID,
        {%endif%}
            PROPERTY_DESCRIPTION,
            PROPERTY_NAME,
            PROPERTY_AMOUNT,
            PROPERTY_QUANTITY,
            PROPERTY_HS_LINE_ITEM_CURRENCY_CODE,
            PROPERTY_HS_MARGIN_ACV,
            PROPERTY_HS_MARGIN_ARR,
            PROPERTY_HS_MARGIN_MRR,
            PROPERTY_HS_MARGIN_TCV,
            PROPERTY_HS_PRICING_MODEL,
            PROPERTY_HS_LASTMODIFIEDDATE,
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
            CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
            CASE WHEN dbt_valid_to IS NULL THEN 1 ELSE 0 END AS Is_Active
    from source
)

select * from cleaned
