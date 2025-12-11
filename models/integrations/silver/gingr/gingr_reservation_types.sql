{% set company = var('company','wagway') %}
{% set sourcesystem = var('sourcesystem','gingr') %}

{{ config(enabled =  (var('sourcesystem','gingr')| lower) == 'gingr') }}

{{ config(
    database = get_target_database(var('company','wagway')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID','SOURCE_DB']
) }}

with raw as 
(
    select *
    from {{ get_raw_source(company, sourcesystem, 'RESERVATION_TYPES') }}

    {% if is_incremental() %}
        where ODS_LAST_UPDATE_DATE > (
            select dateadd(
                day,
                -1,
                coalesce(max(t.ODS_LAST_UPDATE_DATE), '1900-01-01'::timestamp_ntz)
            )
            from {{ this }} t
        )
    or _FIVETRAN_DELETED = true
    {% endif %}
),

cleaned as 
(
    select
        CAST(ID AS BIGINT) AS ID,
        TRIM(SOURCE_DB) AS SOURCE_DB,
        TRIM(TYPE) AS TYPE,
        CAST(TRIM(ODS_LAST_UPDATE_DATE) AS TIMESTAMP_NTZ) AS ODS_LAST_UPDATE_DATE,
        TRIM(DELETE_INDICATOR) AS DELETE_INDICATOR,
        CAST(TRIM(_FIVETRAN_DELETED) AS BOOLEAN) AS _FIVETRAN_DELETED,
        CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned