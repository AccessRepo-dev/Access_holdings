{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'salesforce',
    database = get_target_database(company),
    schema = 'silver',
    unique_key = 'id',
    strategy = 'timestamp',
    updated_at = 'LAST_MODIFIED_DATE',
    invalidate_hard_deletes = True
) }}

select
    TRIM(ID) AS ID,
    TRIM(NAME) AS NAME,
    TRIM(DEVELOPER_NAME) AS DEVELOPER_NAME,
    TRIM(PARENT_ROLE_ID) AS PARENT_ROLE_ID,
    ROLLUP_DESCRIPTION,
    TRIM(FORECAST_USER_ID) AS FORECAST_USER_ID,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE
from {{ get_silver_source(company, 'SALESFORCE_USER_ROLE') }}
where DBT_VALID_TO is null
