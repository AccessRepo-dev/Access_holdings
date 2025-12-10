{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'salesforce') }}
{{ config(enabled = var('company', 'none') == 'zeus') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_crm_location',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with 
source as (
SELECT 
    md5(
        coalesce(A.BILLING_CITY,'') || '|' ||
        coalesce(A.BILLING_STATE,'') || '|' ||
        coalesce(A.BILLING_COUNTRY,'')
        ) as ID,
    A.BILLING_CITY as CITY, 
    A.BILLING_STATE as STATE, 
    A.BILLING_COUNTRY as COUNTRY,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
FROM {{ get_silver_source(company, 'SALESFORCE_OPPORTUNITY') }}  as B 
    LEFT JOIN {{ get_silver_source(company, 'SALESFORCE_ACCOUNT') }}  as A 
        ON A.ACCOUNT_ID = B.ACCOUNT_ID and  A.IS_ACTIVE = 1
    where B.IS_ACTIVE = 1

{% if is_incremental() %}
        WHERE LAST_MODIFIED_DATE > (
            select coalesce(max(LAST_MODIFIED_DATE), '1900-01-01')
            from {{ this }}
        )
    {% endif %}

GROUP BY A.BILLING_CITY, 
    A.BILLING_STATE, 
    A.BILLING_COUNTRY
)

select *
from source