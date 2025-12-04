{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite')  | lower == 'netsuite') }}

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
        FULLNAME AS SUBSIDIARY_FULL_NAME,
        PARENT_NAME,
        CHILD_NAME,
        CURRENCY AS CURRENCY_ID,
        CAST(NULL AS VARCHAR) AS DIVISION_MAPPING,
        ISINACTIVE AS IS_INACTIVE,
        PARENT AS PARENT_ID,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE,
    from {{ ref('netsuite_subsidiary') }}
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