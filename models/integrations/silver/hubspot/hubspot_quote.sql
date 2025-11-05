{% set company = var('company') %} --amh
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['hubspot']) }}
{{ config(enabled = var('company', 'none') in ['amh']) }}


{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'QUOTE',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

SELECT
    ID,
PROPERTY_HS_SENDER_COMPANY_NAME,
PROPERTY_HS_QUOTE_AMOUNT,
PROPERTY_HS_QUOTE_PROGRESSION_STATUS,
PROPERTY_HS_CREATEDATE

from {{ get_raw_source(company, sourcesystem, 'QUOTE') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
