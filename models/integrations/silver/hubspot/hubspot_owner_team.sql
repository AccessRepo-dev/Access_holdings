{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot']
           and var('company') | lower in ['wagway'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_OWNER_TEAM',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

with source as (
    select *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_OWNER_TEAM') }}
    
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
    select
        concat(OWNER_ID,'_',TEAM_ID,'_',to_varchar(DBT_VALID_FROM, 'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        cast(trim(OWNER_ID) as bigint) as OWNER_ID,
        cast(trim(TEAM_ID) as bigint) as TEAM_ID,
        cast(trim(_FIVETRAN_DELETED) as boolean) as _FIVETRAN_DELETED,
        cast(trim(IS_TEAM_PRIMARY) as boolean) as IS_TEAM_PRIMARY,
        cast(trim(_FIVETRAN_SYNCED) as timestamp_tz) as _FIVETRAN_SYNCED,
        current_timestamp()::timestamp_ntz as SILVER_LOAD_DATE,
        cast(DBT_VALID_FROM as timestamp_ntz) as DBT_VALID_FROM,
        cast(DBT_VALID_TO as timestamp_ntz) as DBT_VALID_TO,
        case when DBT_VALID_TO is null then 1 else 0 end as IS_ACTIVE
    from source
)

select * from cleaned
