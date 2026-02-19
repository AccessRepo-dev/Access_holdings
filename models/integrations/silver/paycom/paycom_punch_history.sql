{% set company = var("company", "amh") %}
{% set sourcesystem = var("sourcesystem", "paycom") %}


{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        alias=sourcesystem ~ "_PUNCH_HISTORY",
        unique_key="id_date_key",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns",
    )
}}


with
    raw as (
        select *
        from {{ get_raw_source(company, sourcesystem, "PUNCH_HISTORY") }}

        {% if is_incremental() %}
            where
                cast(_loaded_at as timestamp_ntz) > (
                    select
                        dateadd(
                            day,
                            -1,
                            coalesce(max(_loaded_at), '1900-01-01'::timestamp_ntz)
                        )
                    from {{ this }}
                )
        {% endif %}

    ),
    cleaned as (
        select
            hash(eecode, punchtime) as id_date_key,
            cast(entrytype as int) as entrytype,
            punchtime::TIMESTAMP_TZ as punchtime,
            timeadded::TIMESTAMP_TZ as timeadded,
            trim(eecode) as eecode,
            trim(punchtype) as punchtype,
            trim(punchdesc) as punchdesc,
            trim(deptcode) as deptcode,
            trim(earncode) as earncode,
            cast(taxprofid as int) as taxprofid,
            trim(clocktype) as clocktype,
            cast(hours as float) as hours,
            cast(dollaramount as float) as dollaramount,

            -- TIMESTAMP_TZ
            trim(_etl_batch_id) as _etl_batch_id,
            current_timestamp()::timestamp_ntz as silver_load_date,
            _loaded_at::timestamp_ntz as raw_load_date

        from raw
    )

select *
from cleaned
