{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
    enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot", "hubspot_pawville"]
    and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_COMPANY',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ hs_canonical_company(company, sourcesystem) }},
        _fivetran_synced,
        _FIVETRAN_DELETED,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
    from {{ ref('hubspot_company_snapshot') }}
    {% if is_incremental() %}
        where 
            (_FIVETRAN_SYNCED > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01')) from {{ this }})
        OR 
            (dbt_valid_to > (select dateadd(day, -3, coalesce(max(dbt_valid_to), '1900-01-01')) from {{ this }})))
    {% else %}
        where 1 = 1
    {% endif %}
),

cleaned as (
    select
        ID_DATE_KEY,
            CAST(ID AS NUMBER) AS ID,
            INITCAP(TRIM(PROPERTY_NAME)) AS PROPERTY_NAME,
            TRIM(PROPERTY_DOMAIN) AS PROPERTY_DOMAIN,
            TRIM(PROPERTY_PHONE) AS PROPERTY_PHONE,
            TRIM(PROPERTY_ADDRESS) AS PROPERTY_ADDRESS,
            TRIM(PROPERTY_CITY) AS PROPERTY_CITY,
            TRIM(PROPERTY_STATE) AS PROPERTY_STATE,
            TRIM(PROPERTY_COUNTRY) AS PROPERTY_COUNTRY,
            TRIM(PROPERTY_INDUSTRY) as PROPERTY_INDUSTRY,
            CAST(PROPERTY_HUBSPOT_OWNER_ID AS NUMBER) AS PROPERTY_HUBSPOT_OWNER_ID,
            CAST(PROPERTY_ANNUALREVENUE AS NUMBER) AS PROPERTY_ANNUALREVENUE,
            CAST(PROPERTY_CREATEDATE AS TIMESTAMP_NTZ) AS PROPERTY_CREATEDATE,
            CAST(PROPERTY_HS_LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS PROPERTY_HS_LASTMODIFIEDDATE,
            TRIM(PROPERTY_COMPANY_TYPE) AS PROPERTY_COMPANY_TYPE,
            CAST(TRIM(PROPERTY_NUMBEROFEMPLOYEES) AS NUMBER) AS PROPERTY_NUMBEROFEMPLOYEES,
            _FIVETRAN_SYNCED AS _FIVETRAN_SYNCED,
            _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
            CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
            IS_ACTIVE AS IS_ACTIVE
    from source
)

select *
from cleaned