{% set company = var('company', 'spotless') | lower %}
{% set sourcesystem = var('sourcesystem', 'sage') | lower %}
{{ config(enabled = var('sourcesystem', 'sage') == 'sage' and var('company', 'spotless') in ['spotless','amh']) }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (
    select *
     {% company == 'spotless'%}
    from {{ get_raw_source(company, sourcesystem, 'GL_BATCH_BKP') }}
    {% else %}
    from {{ get_raw_source(company, sourcesystem, 'GL_BATCH') }}
    {%endif%}
    {% if is_incremental() %}
    where 
        cast(WHENMODIFIED as timestamp_ntz) > (
            select dateadd(day, -1, coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz))
            from {{ this }}
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as (
    SELECT

    TRY_CAST(BATCHNO AS INT) AS BATCHNO,

    -- Core Identifiers
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,
    TRIM(BATCH_TITLE) AS BATCH_TITLE,
    
    CAST(BATCH_DATE AS DATE) AS BATCH_DATE,
    CAST(JOURNAL AS VARCHAR) AS JOURNAL,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,
    
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
FROM source_data

)

select *
from cleaned
