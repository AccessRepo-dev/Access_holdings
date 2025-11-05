{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['salesforce']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    alias = 'TASK',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

select
    TRIM(ID) AS ID,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(WHO_ID) AS WHO_ID,
    TRIM(WHAT_ID) AS WHAT_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE
from {{ get_raw_source(company, sourcesystem, 'TASK') }}
{% if is_incremental() and adapter.get_relation(
      database=target.database,
      schema=target.schema,
      identifier=this.name
) is not none %}
where LAST_MODIFIED_DATE > (
    select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
    from {{ this }}
)
     or _FIVETRAN_DELETED = true
    {% endif %}
