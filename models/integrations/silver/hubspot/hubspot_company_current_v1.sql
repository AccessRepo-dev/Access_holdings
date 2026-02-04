{% set company = var('company', 'wagway
') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
    enabled= false,
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_COMPANY_V1',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

{{config(enabled = false)}}

with source as (
    select  concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ crm_company_snapshot(company, sourcesystem) }},
        _fivetran_synced,
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
    select *
    from source
)

select *
from cleaned