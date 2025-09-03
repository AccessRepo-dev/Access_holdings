{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    unique_key = 'ENTITY_ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'ENTITYACCTDEFAULT') }}
),

cleaned as (
    select
        -- Primary Key
        TRIM(ENTITYID) AS ENTITY_ID,

        -- Core Identifiers
        TRIM(ENTITYSTATUS) AS ENTITY_STATUS,
        TRY_CAST(RECORDNO AS INT) AS RECORD_NO,

        -- Audit
        _FIVETRAN_DELETED AS IS_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from source_data
)

select *
from cleaned
