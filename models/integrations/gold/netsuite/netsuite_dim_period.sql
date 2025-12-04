{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_period',
    incremental_strategy = 'merge',
    unique_key = 'DIM_PERIOD_ID'
) }}

with source as (
    select
        ID AS DIM_PERIOD_ID,
        PERIODNAME AS PERIOD_NAME,
        STARTDATE AS START_DATE,
        ENDDATE AS END_DATE,
        CLOSEDONDATE AS CLOSED_ON_DATE,
        ISINACTIVE AS IS_INACTIVE, 
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
        from {{ ref('netsuite_accountingperiod') }}
    --where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source