{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage') }}
{{ config(enabled = var('company', 'spotless') in ['spotless','amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'GLACCTGRPHIERARCHY') }}
    {% if is_incremental() %}
    where cast(_FIVETRAN_SYNCED as timestamp_ntz) > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT
    -- Primary Key
        TRY_CAST(RECORDNO AS INT) AS RECORDNO,

        -- Core Identifiers
        TRY_CAST(ACCOUNTKEY AS INT) AS ACCOUNTKEY,
        TRY_CAST(GLACCTGRPKEY AS INT) AS GLACCTGRPKEY,

        -- Descriptions
        TRIM(ACCOUNTTITLE) AS ACCOUNTTITLE,
        TRIM(ACCOUNTNO) AS ACCOUNTNO,
        TRIM(ACCOUNTTYPE) AS ACCOUNTTYPE,
        TRIM(ACCOUNTNORMALBALANCE) AS ACCOUNTNORMALBALANCE,

        TRIM(GLACCTGRPNAME) AS GLACCTGRPNAME,
        TRIM(GLACCTGRPTITLE) AS GLACCTGRPTITLE,
        TRIM(GLACCTGRPMEMBERTYPE) AS GLACCTGRPMEMBERTYPE,
        TRIM(GLACCTGRPHOWCREATED) AS GLACCTGRPHOWCREATED,
        TRIM(GLACCTGRPNORMALBALANCE) AS GLACCTGRPNORMALBALANCE,

        -- Audit
        CAST(_FIVETRAN_SYNCED AS TIMESTAMP_NTZ) AS _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data

)

select *
from cleaned
