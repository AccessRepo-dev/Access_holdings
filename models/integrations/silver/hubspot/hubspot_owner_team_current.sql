{% set company = var("company", "wagway") | lower %}
{% set sourcesystem = var("sourcesystem", "hubspot") | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower)
        in ["hubspot"]
        and (var("company", "wagway") | lower) in ["wagway"],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_OWNER_TEAM',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select CONCAT(OWNER_ID,'_',TEAM_ID,'_',to_varchar(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) AS ID_DATE_KEY, 
            {{ hs_canonical_owner_team(company, sourcesystem) }}, 
            _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            DBT_VALID_FROM,
            DBT_VALID_TO,
            CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE
    from {{ ref('hubspot_owner_team_snapshot') }}
    
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
        cast(trim(OWNER_ID) as bigint) as OWNER_ID,
        cast(trim(TEAM_ID) as bigint) as TEAM_ID,
        cast(trim(IS_TEAM_PRIMARY) as boolean) as IS_TEAM_PRIMARY,
        cast(trim(_FIVETRAN_SYNCED) as timestamp_tz) as _FIVETRAN_SYNCED,
        SILVER_LOAD_DATE::timestamp_ntz as SILVER_LOAD_DATE,
        cast(DBT_VALID_FROM as timestamp_ntz) as DBT_VALID_FROM,
        cast(DBT_VALID_TO as timestamp_ntz) as DBT_VALID_TO,
        IS_ACTIVE AS IS_ACTIVE
    from source
)

select * from cleaned
