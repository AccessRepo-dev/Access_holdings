{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot'] and var('company') | lower in ['playfly','amh'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_PRODUCT',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_PRODUCT') }}
    
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
   SELECT
   CONCAT(ID,'_',TO_VARCHAR(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY, 
    CAST(ID AS INT)  AS product_id,
    

    /* ---------- Name ---------- */
    INITCAP(TRIM(PROPERTY_NAME))               AS product_name,

   
    {% if company in ['playfly', 'wagway'] %}
        INITCAP(TRIM(PROPERTY_DESCRIPTION)) AS PROPERTY_DESCRIPTION,
        INITCAP(TRIM(PROPERTY_FAMILY)) AS PROPERTY_FAMILY,
    {% else %}
        CAST(NULL AS VARCHAR) AS PROPERTY_DESCRIPTION,
        CAST(NULL AS VARCHAR) AS PROPERTY_FAMILY,
    {% endif %}
                                    
    /* ---------- Product Type ---------- */
    
    {% if company in ['amh', 'playfly'] %}
        PORTAL_ID::NUMBER                        AS portal_id,
        LOWER(TRIM(PROPERTY_HS_PRICING_MODEL)) AS pricing_model,
        LOWER(TRIM(PROPERTY_HS_STATUS)) AS product_status,
    {% else %}
        CAST(NULL AS NUMBER) AS portal_id,
        CAST(NULL AS VARCHAR) AS pricing_model,
        CAST(NULL AS VARCHAR) AS product_status,
    {% endif %}

    {% if company in ['amh'] %}
        LOWER(TRIM(PROPERTY_HS_PRODUCT_TYPE)) AS product_type,
    {% elif company == 'playfly' %}
        LOWER(TRIM(PROPERTY_PRODUCT_CATEGORY)) AS product_type,
    {% else %}
        CAST(NULL AS VARCHAR) AS product_type,
    {% endif %}

  
    CAST(PROPERTY_PRICE AS FLOAT)      AS price,

  

    /* ---------- Timestamps ---------- */
    {%if company == 'wagway'%}
    PROPERTY_HS_CREATEDATE   AS created_at,
    {% else %}
    PROPERTY_CREATEDATE   AS created_at,
    {% endif %}
    PROPERTY_HS_LASTMODIFIEDDATE AS updated_at,

    /* ---------- Fivetran Metadata ---------- */
    COALESCE(_FIVETRAN_DELETED, FALSE)         AS is_deleted,
    _FIVETRAN_SYNCED      AS synced_at

FROM source
)

select * from cleaned
