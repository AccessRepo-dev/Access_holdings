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
from {{ get_raw_source(company, sourcesystem, 'CAMPAIGN') }}
{% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true

{% endif %}

),

cleaned as 
(
    select
    TRIM(ID) AS ID,
    TRIM(NAME) AS NAME,
    TRIM(STATUS) AS STATUS,
    CAST(START_DATE AS TIMESTAMP_NTZ) AS START_DATE,
    CAST(END_DATE AS TIMESTAMP_NTZ) AS END_DATE,
    EXPECTED_REVENUE,
    BUDGETED_COST,
    ACTUAL_COST,
    NUMBER_SENT,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    CAST(CREATED_DATE AS TIMESTAMP_NTZ) AS CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS  LAST_MODIFIED_DATE
    from raw
)

select * from cleaned
