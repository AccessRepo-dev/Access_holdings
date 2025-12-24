{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage' and var('company', 'spotless') in ['spotless','amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'CURRENCY') }}
    {% if is_incremental() %}
    where 
        cast(UPDATED_AT as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(UPDATED_AT), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT
    -- Primary Key
    TRY_CAST(ID AS INT) AS ID,

    -- Core Info
    --TRIM(CURRENCY_NAME) AS CURRENCY_NAME,
    TRIM(NAME) AS NAME,
    TRIM(SYMBOL) AS SYMBOL,

    -- Audit Info
    TRY_CAST(UPDATED_AT AS TIMESTAMP_NTZ) AS UPDATED_AT,

    -- Flags / Deletes
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,

    -- Load Audit
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    _FIVETRAN_SYNCED
FROM source_data

)

select *
from cleaned
