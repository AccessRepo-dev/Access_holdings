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
    TRIM(PRODUCT_CODE) AS PRODUCT_CODE,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    FAMILY,
    TRIM(IS_ACTIVE) AS IS_ACTIVE,
    CREATED_DATE,
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    QUANTITY_UNIT_OF_MEASURE,
from {{ get_silver_source(company, 'SALESFORCE_PRODUCT_2') }}
where DBT_VALID_TO is null
