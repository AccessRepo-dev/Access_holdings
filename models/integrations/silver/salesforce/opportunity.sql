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
    TRIM(ACCOUNT_ID) AS ACCOUNT_ID,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(NAME) AS NAME,
    TRIM(STAGE_NAME) AS STAGE_NAME,
    AMOUNT,
    CLOSE_DATE,
    PROBABILITY,
    TRIM(LEAD_SOURCE) AS LEAD_SOURCE,
    TRIM(CAMPAIGN_ID) AS CAMPAIGN_ID,
    TRIM(FORECAST_CATEGORY_NAME) AS FORECAST_CATEGORY_NAME,
    TRIM(IS_CLOSED) AS IS_CLOSED,
    TRIM(IS_WON) AS IS_WON,
    NEXT_STEP,
    CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    TRIM(DESCRIPTION) AS DESCRIPTION
from {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}
where DBT_VALID_TO is null
