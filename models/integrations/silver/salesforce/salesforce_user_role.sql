{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'id',
    materialized = 'incremental',
    incremental_strategy = 'merge'
) }}

with raw as 
(
select *

from {{ source_snapshot_schema(company, 'SALESFORCE_USER_ROLE') }}
{% if is_incremental() %}
    where 
        LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01'::timestamp_ntz)
            from {{ this }})
        and DBT_VALID_TO is null
{% else %}
    where DBT_VALID_TO is null
{% endif %}
)

select
    TRIM(ID) AS ID,
    TRIM(NAME) AS NAME,
    TRIM(DEVELOPER_NAME) AS DEVELOPER_NAME,
    TRIM(PARENT_ROLE_ID) AS PARENT_ROLE_ID,
    ROLLUP_DESCRIPTION,
    TRIM(FORECAST_USER_ID) AS FORECAST_USER_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from raw
