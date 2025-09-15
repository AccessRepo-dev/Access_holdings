{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ITEMID'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'ITEM') }}

    {% if is_incremental() %}
        where WHENMODIFIED > (
            select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
    {% endif %}

),

cleaned as (

    SELECT
    -- Primary Key
    TRIM(ITEMID) AS ITEMID,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(NAME) AS NAME,
    TRIM(ITEMTYPE) AS ITEMTYPE,
    CASE WHEN STATUS = 'active' then False 
         WHEN STATUS = 'inactive' then True
        ELSE NULL
    END AS STATUS,
    TRIM(COST_METHOD) AS COST_METHOD,
    STANDARD_COST AS STANDARD_COST,

    -- Extra
    TRIM(EXTENDED_DESCRIPTION) AS EXTENDED_DESCRIPTION,
   
    CASE WHEN ENABLEFULFILLMENT = 'F' then False 
         WHEN ENABLEFULFILLMENT = 'T' then True
        ELSE NULL
    END AS ENABLEFULFILLMENT,

    -- Dates
    CAST(WHENCREATED AS TIMESTAMP_NTZ) AS WHENCREATED,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,
    

    -- Audit
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data

)

select *
from cleaned
