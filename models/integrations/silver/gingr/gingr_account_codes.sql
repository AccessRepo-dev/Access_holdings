{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(enabled = (var('company') | lower) ==  'wagway' and (var('sourcesystem')| lower) == 'gingr') }}

{{ config(
    database=get_target_database(var('company')),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ID','SOURCE_DB']
) }}

with raw as 
(
select *
from {{ get_raw_source(company, sourcesystem, 'ACCOUNT_CODES') }}
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
    CAST(TRIM(ID) AS INT) AS ID,
	TRIM(SOURCE_DB) AS SOURCE_DB,
	TRIM(CODE) AS CODE,
	TRIM(LABEL) AS LABEL,
	CAST(TRIM(PARENT_ID) AS INT) AS PARENT_ID,
	CAST(TRIM(IS_DELETED) AS BOOLEAN) AS IS_DELETED,
	TRIM(MD5_HASH) AS MD5_HASH,
	CAST(TRIM(ODS_LAST_UPDATE_DATE) AS TIMESTAMP_NTZ) AS ODS_LAST_UPDATE_DATE,
	TRIM(DELETE_INDICATOR) AS DELETE_INDICATOR,
	CAST(TRIM(_FIVETRAN_DELETED) AS BOOLEAN) AS _FIVETRAN_DELETED,
	CAST(TRIM(_FIVETRAN_SYNCED) AS TIMESTAMP_TZ) AS _FIVETRAN_SYNCED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from raw
)

select * from cleaned
