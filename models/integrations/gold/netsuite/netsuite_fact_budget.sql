{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'BUDGET_ID'
) }}

with source as (
    select
        ABS(HASH(ACCOUNT, SUBSIDIARY)) as DIM_ACCOUNT_ID,
        ID AS BUDGET_ID,
        ACCOUNT AS ACCOUNT_ID,
        AMOUNT AS AMOUNT,
        CATEGORY AS CATEGORY_ID,
        CLASS AS CLASS_ID,
        CSEG1 AS CSEG1_ID,
        CSEG3 AS CSEG3_ID,
        --CSEG_CP_STORE_LOC AS CSEG_CP_STORE_LOC_ID,
        CURRENCY AS CURRENCY_ID,
        CUSTOMER AS CUSTOMER_ID,
        DEPARTMENT AS DEPARTMENT_ID,
        ITEM AS ITEM_ID,
        LOCATION AS LOCATION_ID,
        PERIOD AS PERIOD_ID,
        SUBSIDIARY AS SUBSIDIARY_ID,
        LASTMODIFIEDDATE AS LAST_MODIFIED_DATE
    from {{ get_silver_source(company, 'netsuite_budgetlegacy') }}
    where (_fivetran_deleted is null or _fivetran_deleted = false)
    {% if is_incremental() %}
      and LASTMODIFIEDDATE > (
          select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
          from {{ this }}
      )
    {% endif %}
)

select *
from source
