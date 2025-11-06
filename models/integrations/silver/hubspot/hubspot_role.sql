{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem', 'none') in ['hubspot', 'hubspot_pawville'],
    materialized = 'incremental',
    database = get_target_database(company),
    alias = sourcesystem ~ '_ROLE',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}


select
    CAST(ID AS NUMBER) AS ID,
    TRIM(NAME) AS NAME,
    _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from {{ get_raw_source(company, sourcesystem, 'ROLE') }}

{% if is_incremental() %}
where _FIVETRAN_SYNCED > (
    select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
    from {{ this }}
)
or _FIVETRAN_DELETED = true
{% endif %}
