{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_class',
    incremental_strategy = 'merge',
    unique_key = 'DIM_CLASS_ID'
) }}

with source as (
    SELECT
        ABS(HASH(c.ID,s.SUBSIDIARY)) AS DIM_CLASS_ID,
        ID AS CLASS_ID,
        s.SUBSIDIARY AS SUBSIDIARY_ID,
        NAME,
        FULLNAME,
        PARENT AS PARENT_ID,
        ISINACTIVE AS IS_INACTIVE,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'CLASSIFICATION') }} c
    LEFT JOIN {{ get_silver_source(company, 'CLASSIFICATIONSUBSIDIARYMAP') }} s ON c.ID = s.CLASSIFICATION
    {% if is_incremental() %}
    and LASTMODIFIEDDATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
        from {{ this }}
    )
    {% endif %}
)
select *
from source