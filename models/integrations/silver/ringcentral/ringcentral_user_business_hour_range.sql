{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(enabled =(var('company') | lower) ==  'wagway' and (var('sourcesystem')| lower) =='ringcentral') }}

{{ config(
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['EXTENSION_ID', 'DAY', 'INDEX']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'USER_BUSINESS_HOUR_RANGE') }}
{% if is_incremental() %}
    where LAST_MODIFIED_DATE > (
        select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )

{% endif %}

),

cleaned as 
(
    select
    TRIM(EXTENSION_ID) AS EXTENSION_ID,
	TRIM(DAY) AS DAY,
	CAST(TRIM(INDEX) AS INT) AS INDEX,
	TRIM("FROM") AS "FROM",
	TRIM("TO") AS "TO",
	CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
