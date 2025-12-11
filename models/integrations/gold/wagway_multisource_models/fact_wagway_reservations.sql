{{ config(
    database = get_target_database('wagway'),
    materialized = 'table',
    alias = 'FACT_WAGWAY_RESERVATIONS'
) }}

SELECT
    r.ID,
    r.SOURCE_DB,
    r.LOCATION_ID,
    r.OWNER_ID,
    r.ANIMAL_ID,
    r.TYPE_ID,
    r.CLASS_ID,
    r.START_DATE,
    r.END_DATE,
    r.CREATED_AT,
    r.CANCEL_STAMP,
    r.CONFIRMED_STAMP,
    r.WAIT_LIST_STAMP,
    r.WAIT_LIST_ACCEPTED_STAMP,
    r.CHECK_IN_STAMP,
    r.CHECK_OUT_STAMP,
    r.DELETE_INDICATOR,
    t.TYPE,
    CONVERT_TIMEZONE('Asia/Kolkata', CURRENT_TIMESTAMP()::TIMESTAMP_NTZ) AS LAST_REFRESH_DATE

FROM {{ get_silver_source('wagway', 'gingr_reservations') }} r
LEFT JOIN {{ get_silver_source('wagway', 'gingr_reservation_types') }} t
    ON CONCAT(r.TYPE_ID, r.SOURCE_DB) = CONCAT(t.ID, t.SOURCE_DB)
