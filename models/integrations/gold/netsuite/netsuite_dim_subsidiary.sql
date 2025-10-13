{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_subsidiary',
    incremental_strategy = 'merge',
    unique_key = 'DIM_SUBSIDIARY_ID'
) }}

with source as (
    select
        ID AS DIM_SUBSIDIARY_ID,
        FULLNAME AS SUBSIDIARY_NAME,
        SUB_NAME1,
        SUB_NAME2,
        SUB_NAME3,
        SUB_NAME4,
        SUB_NAME5,
        CURRENCY AS CURRENCY_ID,
        ISINACTIVE AS IS_INACTIVE,
        PARENT AS PARENT_ID,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
    from {{ get_silver_source(company, 'SUBSIDIARY') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
    and LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source