{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'budgetcategory',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with cleaned as (
    select
        CAST(ID AS INT) AS ID,
        CAST(
            CASE 
                WHEN BUDGETTYPE = 'T' THEN TRUE
                WHEN BUDGETTYPE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS BUDGETTYPE,
        CAST(
            CASE 
                WHEN ISINACTIVE = 'T' THEN TRUE
                WHEN ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS ISINACTIVE,
        TRIM(NAME) AS NAME,
        _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CAST(_FIVETRAN_SYNCED AS TIMESTAMP_NTZ) AS _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from {{ get_raw_source(company, sourcesystem, 'BUDGETCATEGORY') }}
    {% if is_incremental() %}
    where _FIVETRAN_SYNCED > (
        select coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
)

select 
    *
from cleaned