{% set company = var("company", "wagway") %}

{{
    config(
        enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"]
        and company in ["wagway", "playfly", "amh"]
    )
}}

{{ config(
    database = get_target_database(company),
    alias = 'dim_owner',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['OWNER_ID','SOURCE_SCHEMA']
) }}

SELECT
    ID_DATE_KEY,
    md5(   
        coalesce(nullif(cast(OWNER_ID as string),''), '') || '|' ||
        'HUBSPOT'
        ) as OWNER_ID,
    case when CONCAT(FIRST_NAME,LAST_NAME) = '' or CONCAT(FIRST_NAME,LAST_NAME) is null then 'Unknown' else CONCAT(FIRST_NAME,' ',LAST_NAME) end AS NAME ,
    EMAIL,
    is_active,
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_OWNER') }} 

{% if company == 'wagway'%} 

UNION ALL 

SELECT
    ID_DATE_KEY,
    md5(   
        coalesce(nullif(cast(OWNER_ID as string),''), '') || '|' ||
        'HUBSPOT_PAWVILLE'
        ) as OWNER_ID,
    case when CONCAT(FIRST_NAME,LAST_NAME) = '' or CONCAT(FIRST_NAME,LAST_NAME) is null then 'Unknown' else CONCAT(FIRST_NAME,' ',LAST_NAME) end AS NAME ,
    EMAIL,
    is_active,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_OWNER') }} 
{% endif %}