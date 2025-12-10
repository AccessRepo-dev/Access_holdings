{% set company = var('company', 'wagway') | lower %}
{{ config(enabled = var('sourcesystem', 'netsuite') | lower == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_class',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CLASS_ID'
) }}

with source as (
    SELECT
        c.ID AS DIM_CLASS_ID,
        ID AS CLASS_ID,
        NAME,
        FULLNAME,
        PARENT_CLASS,
        PARENT AS PARENT_ID,
        ISINACTIVE AS IS_INACTIVE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ ref('netsuite_classification') }} c
    where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
    AND  LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source