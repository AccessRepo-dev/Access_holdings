{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

select 
     TRY_CAST(ID AS INT) AS ID,
    TRY_CAST(POSTINGPERIOD AS INT) AS POSTINGPERIOD,
    TRY_CAST(FROMSUBSIDIARY AS INT) AS FROMSUBSIDIARY,
    TRY_CAST(FROMCURRENCY AS INT) AS FROMCURRENCY,
    TRY_CAST(TOSUBSIDIARY AS INT) AS TOSUBSIDIARY,
    TRY_CAST(TOCURRENCY AS INT) AS TOCURRENCY,
    TRY_CAST(ACCOUNTINGBOOK AS INT) AS ACCOUNTINGBOOK,
    AVERAGERATE,
    CURRENTRATE,
    HISTORICALRATE,
    _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
from {{ get_raw_source(company, sourcesystem, 'CONSOLIDATEDEXCHANGERATE') }}
    
