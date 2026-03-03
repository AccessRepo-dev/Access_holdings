{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce", "salesforce_access_holdings"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        alias = sourcesystem ~ '_OPPORTUNITY_FIELD_HISTORY',
        schema="silver",
        unique_key="ID_DATE_KEY",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns",
    )
}}

with
    raw as (
        select concat(id,'_',to_varchar(dbt_valid_from,'YYYYMMDDHH24MISSFF3')) as ID_DATE_KEY,
        {{ sf_canonical_opportunity_field_history(company, sourcesystem) }},
        _FIVETRAN_DELETED,
        _fivetran_synced,
        current_timestamp() as silver_load_date,
        dbt_valid_from,
        dbt_valid_to,
        case when dbt_valid_to is null then 1 else 0 end as is_active
        from {{ ref("salesforce_opportunity_field_history_snapshot") }}
    {% if is_incremental()%}
    where 
        cast(_FIVETRAN_SYNCED as timestamp_ntz) > (select dateadd(day, -3, coalesce(max(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)) from {{ this }})
    {% endif %}
    ),

    cleaned as (
        select
            ID_DATE_KEY AS ID_DATE_KEY,
            TRIM(ID) AS ID,
            TRIM(OPPORTUNITY_ID) AS OPPORTUNITY_ID,
            IS_DELETED AS IS_DELETED,
            TRIM(CREATED_BY_ID) AS CREATED_BY_ID,
            CAST(CREATED_DATE AS TIMESTAMP_NTZ) AS CREATED_DATE,
            TRIM(FIELD) AS FIELD,
            TRIM(DATA_TYPE) AS DATA_TYPE,
            TRIM(OLD_VALUE) AS OLD_VALUE,
            TRIM(NEW_VALUE) AS NEW_VALUE,
            CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
            CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
            CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
            _FIVETRAN_SYNCED::TIMESTAMP_NTZ  AS _FIVETRAN_SYNCED,
            _FIVETRAN_DELETED AS _FIVETRAN_DELETED,
            IS_ACTIVE AS IS_ACTIVE
        from raw
    )

select *
from cleaned
