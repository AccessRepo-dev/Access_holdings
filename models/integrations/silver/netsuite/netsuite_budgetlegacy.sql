{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'budgetlegacy',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with cleaned as (
    select
        TRY_CAST(ID AS INT) AS ID,
        TRY_CAST(ACCOUNT AS INT) AS ACCOUNT,
        AMOUNT,
        TRY_CAST(CATEGORY AS INT) AS CATEGORY,
        TRY_CAST(CLASS AS INT) AS CLASS,
        TRY_CAST(CSEG1 AS INT) AS CSEG1,
        TRY_CAST(CSEG3 AS INT) AS CSEG3,
         {% if company == 'playfly' and sourcesystem == 'netsuite' %}
            CSEG_MHI_SCHOOL_YR AS CSEG,
        {% else %}
            CSEG_CP_STORE_LOC AS CSEG,
        {% endif%}
        TRY_CAST(CURRENCY AS INT) AS CURRENCY,
        TRY_CAST(CUSTOMER AS INT) AS CUSTOMER,
        TRY_CAST(DEPARTMENT AS INT) AS DEPARTMENT,
        TRY_CAST(ITEM AS INT) AS ITEM,
        LASTMODIFIEDDATE,
        {% if company == 'wagway' and sourcesystem == 'netsuite' %}
            CSEG_CP_STORE_LOC AS LOCATION,
        {% else %}
            LOCATION,
        {% endif%}
        TRY_CAST(PERIOD AS INT) AS PERIOD,
        TRY_CAST(SUBSIDIARY AS INT) AS SUBSIDIARY,
        _FIVETRAN_DELETED,
        CAST(_FIVETRAN_SYNCED AS TIMESTAMP_NTZ) AS _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE

    from {{ get_raw_source(company, sourcesystem, 'BUDGETLEGACY') }}
    {% if is_incremental() %}
    where LASTMODIFIEDDATE > (
        select coalesce(max(LASTMODIFIEDDATE), '1900-01-01'::timestamp_ntz)
        from {{ this }}
    )
    or _FIVETRAN_DELETED = true
    {% endif %}
)

select 
    *
from cleaned