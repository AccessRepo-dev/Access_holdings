{% set company = var('company') %}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_RINGCENTRAL_SMS'
) }}

 --config -- mater
select
	a.ID,
	a.BATCH_ID,
	a.CREATION_TIME,
	a.LAST_MODIFIED_TIME,
	a.MESSAGE_STATUS,
	a.SEGMENT_COUNT,
	a.TEXT,
	a.COST,
	a.DIRECTION,
	a.ERROR_CODE,
	a.from_phone as from_phone,
    b.value as "TO",
	a._FIVETRAN_SYNCED
FROM {{ get_silver_source('wagway', 'ringcentral_sms') }}  A
JOIN {{ get_silver_source('wagway', 'ringcentral_sms_to') }}  B ON A.id = B.SMS_ID