{% set company = var('company') %} --wagway , playfly
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville']) }}



{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias =  sourcesystem ~ '_OWNER',
    incremental_strategy = 'merge',
    unique_key = 'OWNER_ID'
) }}

SELECT
    CAST(TRIM(OWNER_ID) AS INT) AS OWNER_ID,
    INITCAP(TRIM(FIRST_NAME)) AS FIRST_NAME,
    INITCAP(TRIM(LAST_NAME)) AS LAST_NAME,
    LOWER(TRIM(EMAIL)) AS EMAIL,
    _FIVETRAN_SYNCED

from {{ get_raw_source(company, sourcesystem, 'OWNER') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
