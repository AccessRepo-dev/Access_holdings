{% set company = var('company') %}

{{ config(
    enabled = (var('company') | lower) == 'wagway',
    database = get_target_database(company),
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
    b.location as to_location
from {{ get_silver_source('wagway', 'ringcentral_message') }} a
left join {{ get_silver_source('wagway', 'ringcentral_message_to') }} b
    on a.id = b.message_id
where a.type = 'SMS'