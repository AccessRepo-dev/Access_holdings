{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite' and var('company', 'none') == 'playfly' )}}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    from {{ get_raw_source(company, sourcesystem, 'CUSTOMRECORD_CSEG2') }}
    {% if is_incremental() %}
    where 
        cast(LASTMODIFIED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(LASTMODIFIED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    select
       CAST(ID AS INT) AS ID,
       CASE WHEN ISINACTIVE = 'F' THEN false ELSE True END AS ISINACTIVE,
       TRIM(NAME) AS NAME,
        CAST(LASTMODIFIED AS TIMESTAMP_NTZ) AS LASTMODIFIED,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data
)

select
    *
from cleaned