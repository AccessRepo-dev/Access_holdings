{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['salesforce']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'CAMPAIGN',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

select
    ID,
    NAME,
    STATUS,
    START_DATE,
    END_DATE,
    EXPECTED_REVENUE,
    BUDGETED_COST,
    ACTUAL_COST,
    NUMBER_SENT,
    OWNER_ID,
    DESCRIPTION,
    CREATED_DATE,
    LAST_MODIFIED_DATE
from {{ get_raw_source(company, sourcesystem, 'CAMPAIGN') }}
    {% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
