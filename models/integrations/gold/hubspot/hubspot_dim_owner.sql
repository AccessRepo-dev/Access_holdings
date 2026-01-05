{% set company = var("company") %}
{% set sourcesystem = var("sourcesystem") | upper %}


{{
    config(
        enabled=(var("sourcesystem") | lower) in ["hubspot", "hubspot_pawville"]
        and (var("company") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="dim_owner",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["OWNER_ID", "SOURCE_SCHEMA"],
    )
}}

select
    id_date_key,
    md5(
        coalesce(nullif(cast(owner_id as string), ''), '') || '|' || 'HUBSPOT'
    ) as owner_id,
    case
        when concat(first_name, last_name) = '' or concat(first_name, last_name) is null
        then 'Unknown'
        else concat(first_name, ' ', last_name)
    end as name,
    email,
    is_active,
    'HUBSPOT' as source_schema,
    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_OWNER") }}

{% if company == "wagway" %}

    union all

    select
        id_date_key,
        md5(
            coalesce(nullif(cast(owner_id as string), ''), '')
            || '|'
            || 'HUBSPOT_PAWVILLE'
        ) as owner_id,
        case
            when
                concat(first_name, last_name) = ''
                or concat(first_name, last_name) is null
            then 'Unknown'
            else concat(first_name, ' ', last_name)
        end as name,
        email,
        is_active,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_OWNER") }}
{% endif %}
