{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['ringcentral']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'COMPANY_DIRECTORY_PHONE_NUMBER') }}
{% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )

{% endif %}

),

cleaned as 
(
    select
    TRIM(PHONE_NUMBER),
    CAST(TRIM(COMPANY_DIRECTORY_ID) AS BIGINT),
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
