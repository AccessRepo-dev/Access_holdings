{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}
{{ config(enabled = var('sourcesystem', 'none') in ['salesforce']) }}

{{ config(
    
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'CASE') }}
    {% if is_incremental()%}
    where
        LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
            from {{ this }})
        or _FIVETRAN_DELETED = true
    {% else %}
    where 
        _FIVETRAN_DELETED = true
    {% endif %}
),


cleaned as 
(
    select
    TRIM(ID) AS ID,
    TRIM(ACCOUNT_ID) AS ACCOUNT_ID,
    TRIM(CONTACT_ID) AS CONTACT_ID,
    CAST(CLOSED_DATE AS TIMESTAMP_NTZ) AS CLOSED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE
    from raw
)

select * from cleaned
