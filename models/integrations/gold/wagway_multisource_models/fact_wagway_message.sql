{{ config(
    database = get_target_database('wagway'),
    materialized = 'table',
    alias = 'FACT_WAGWAY_MESSAGE'
) }}

-- Updated logic to match Snowflake SQL
select
    a.id,
    a.extension_id,
    a.direction,
    a.from_location,
    b.phone_number,
    b.name,
    b.location as to_location,
    a.CREATION_TIME,
    CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS LAST_REFRESH_DATE

from {{ ref('ringcentral_message') }} a
left join {{ ref('ringcentral_message_to') }} b
    on a.id = b.message_id
where a.type = 'SMS'