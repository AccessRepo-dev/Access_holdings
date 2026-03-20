{% set company = var('company', 'zeus') %}
{% set sourcesystem = var('sourcesystem', 'salesforce') %}
 
      
{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
    database = get_target_database(company),
    alias = sourcesystem ~ '_OPPORTUNITY',
    schema = 'silver',
    unique_key = 'ID_DATE_KEY',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    on_schema_change='sync_all_columns'
) }}

with raw as 
(
select  concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ sf_canonical_opportunity(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
from {{ ref('salesforce_opportunity_snapshot') }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
    
),


cleaned as 
(
select
    ID_DATE_KEY AS ID_DATE_KEY,
    TRIM(ID) AS ID,
    TRIM(ACCOUNT_ID) AS ACCOUNT_ID,
    TRIM(OWNER_ID) AS OWNER_ID,
    TRIM(NAME) AS NAME,
    TRIM(STAGE_NAME) AS STAGE_NAME,
    AMOUNT AS AMOUNT,
    INSTALL_AMOUNT_C AS INSTALL_AMOUNT_C,
    CLOSE_DATE AS CLOSE_DATE,
    PROBABILITY AS PROBABILITY,
    TRIM(LEAD_SOURCE) AS LEAD_SOURCE,
    TRIM(CAMPAIGN_ID) AS CAMPAIGN_ID,
    TRIM(FORECAST_CATEGORY_NAME) AS FORECAST_CATEGORY_NAME,
    TRIM(SYSTEM_SUB_TYPE_C) as SYSTEM_SUB_TYPE_C, 
    TOTAL_CONTRACT_VALUE_CURRENCY_C AS TOTAL_CONTRACT_VALUE_CURRENCY_C,
    IS_CLOSED AS IS_CLOSED,
    IS_WON AS IS_WON,
    NEXT_STEP AS NEXT_STEP,
    CREATED_DATE AS CREATED_DATE,
    TRIM(DESCRIPTION) AS DESCRIPTION,
    LOSS_REASON_C AS LOSS_REASON_C, 
    CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
    CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
    CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
    _FIVETRAN_SYNCED::timestamp_ntz  AS _FIVETRAN_SYNCED,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    Is_Active AS Is_Active
from raw
)

SELECT * FROM cleaned