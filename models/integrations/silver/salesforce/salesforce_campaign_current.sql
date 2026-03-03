{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        alias = sourcesystem ~ '_CAMPAIGN',
        schema="silver",
        unique_key="ID_DATE_KEY",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns",
    )
}}


with
    raw as (
        select distinct
            concat(
                id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
            ) as id_date_key,
         {{ sf_canonical_campaign(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
        from {{ ref("salesforce_campaign_snapshot") }}
        {% if is_incremental() %}
           {% if is_incremental()%}
        where 
            cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -1, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
        {% endif %}
    {% endif %}
    ),

    cleaned as (
        select ID_DATE_KEY,
            TRIM(CAMPAIGN_ID) AS CAMPAIGN_ID,
            TRIM(NAME) AS NAME,
            TRIM(TYPE) AS TYPE,
            TRIM(STATUS) AS STATUS,
            CAST(START_DATE AS TIMESTAMP_NTZ) AS START_DATE,
            CAST(END_DATE AS TIMESTAMP_NTZ) AS END_DATE,
            CAST(EXPECTED_REVENUE AS NUMBER) AS EXPECTED_REVENUE,
            CAST(BUDGETED_COST AS NUMBER) AS BUDGETED_COST,
            CAST(ACTUAL_COST AS NUMBER) AS ACTUAL_COST,
            NUMBER_SENT AS NUMBER_SENT,
            TRIM(OWNER_ID) AS OWNER_ID,
            TRIM(DESCRIPTION) AS DESCRIPTION,
            CAST(CREATED_DATE AS TIMESTAMP_NTZ) AS CREATED_DATE,
            CAST(LAST_MODIFIED_DATE AS TIMESTAMP_NTZ) AS LAST_MODIFIED_DATE,
            _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
            _FIVETRAN_SYNCED as _FIVETRAN_SYNCED,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
            CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
            IS_ACTIVE as IS_ACTIVE
        from raw
    )

select *
from cleaned
