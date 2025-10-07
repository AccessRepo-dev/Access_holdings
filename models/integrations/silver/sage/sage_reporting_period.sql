{% set company = var('company', 'unknown_company') | lower %}
{% set sourcesystem = var('sourcesystem', 'unknown_source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'reporting_period',
    incremental_strategy = 'merge',
    unique_key = 'RECORDNO'
) }}

with source_data as (

    select *
    from {{ get_raw_source(company, sourcesystem, 'REPORTING_PERIOD') }}
    
    {% if is_incremental() %}
    where 
        (
            HEADER_1 ilike '%month%' and START_DATE is not null
            and cast(WHENMODIFIED as timestamp_ntz) > (
                select coalesce(max(WHENMODIFIED), '1900-01-01'::timestamp_ntz)
                from {{ this }}
            )
        )
        or _FIVETRAN_DELETED = true
    {% else %}
    WHERE
    HEADER_1 ilike '%month%' and START_DATE is not null
    {% endif %}


),

cleaned as (

   SELECT
    -- Primary Key
    TRY_CAST(RECORDNO AS INT) AS RECORDNO,

    -- Core Info
    TRIM(NAME) AS NAME,
    CASE 
        WHEN STATUS = 'active' THEN FALSE 
        ELSE TRUE 
    END AS STATUS,
    -- Dates
    CAST(START_DATE AS DATE) AS START_DATE,
    CAST(YEAR(START_DATE) || LPAD(MONTH(START_DATE), 2, '0') || LPAD(DAY(START_DATE), 2, '0')AS INTEGER) AS DATE_KEY,
    CAST(END_DATE AS DATE) AS END_DATE,
    CAST(WHENMODIFIED AS TIMESTAMP_NTZ) AS WHENMODIFIED,

    -- Fivetran
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    -- Silver Load Metadata
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

FROM source_data


)

select *
from cleaned
