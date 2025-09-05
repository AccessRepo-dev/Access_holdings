{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'POSTING_PERIOD_ID'
) }}

with source as (
    select
        ID AS POSTING_PERIOD_ID,
        CLOSEDONDATE AS CLOSED_ON_DATE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
        ENDDATE AS END_DATE,
        PERIODNAME AS PERIOD_NAME,
        STARTDATE AS START_DATE,
        YEAR AS YEAR
    from {{ get_silver_source(company, 'netsuite_accountingperiod') }}
    --where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
    and LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source