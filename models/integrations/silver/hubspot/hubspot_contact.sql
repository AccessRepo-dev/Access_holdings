{% set company = var('company') %}
{% set sourcesystem  = var('sourcesystem') | upper %}

{{ config(
    enabled = var('sourcesystem') | lower in ['hubspot', 'hubspot_pawville'],
    database = get_target_database(var('company')),
    materialized = 'incremental',
    alias = sourcesystem ~ '_CONTACT',
    incremental_strategy = 'merge',
    unique_key = 'ID_DATE_KEY'
) }}

WITH raw AS (

    SELECT *
    from {{ source_snapshot_schema(company, sourcesystem ~ '_CONTACT') }}

    {% if is_incremental() %}
        WHERE _FIVETRAN_SYNCED > (
            SELECT COALESCE(MAX(_FIVETRAN_SYNCED), '1900-01-01'::timestamp_ntz)
            FROM {{ this }}
        )
        AND 1 = 1
    {% else %}
        WHERE 1 = 1
    {% endif %}

),

cleaned AS (

    SELECT
        CONCAT(ID, '_', TO_VARCHAR(DBT_VALID_FROM, 'MMDDYYYY')) AS ID_DATE_KEY,
        CAST(TRIM(ID) AS INT) AS ID,
        INITCAP(TRIM(PROPERTY_FIRSTNAME)) AS PROPERTY_FIRSTNAME,
        INITCAP(TRIM(PROPERTY_LASTNAME)) AS PROPERTY_LASTNAME,
        LOWER(TRIM(PROPERTY_EMAIL)) AS PROPERTY_EMAIL,

        -- Clean phone numbers (remove spaces, parentheses, dashes)
        REGEXP_REPLACE(TRIM(PROPERTY_PHONE), '[^0-9]', '') AS PROPERTY_PHONE,
        REGEXP_REPLACE(TRIM(PROPERTY_MOBILEPHONE), '[^0-9]', '') AS PROPERTY_MOBILEPHONE,
        REGEXP_REPLACE(TRIM(PROPERTY_HS_CALCULATED_PHONE_NUMBER), '[^0-9]', '') AS PROPERTY_HS_CALCULATED_PHONE_NUMBER,
        REGEXP_REPLACE(TRIM(PROPERTY_HS_CALCULATED_MOBILE_NUMBER), '[^0-9]', '') AS PROPERTY_HS_CALCULATED_MOBILE_NUMBER,
        {% if company | lower == 'wagway' and sourcesystem | lower == 'hubspot' %}
        PROPERTY_CLUB_C,
        PROPERTY_GINGR_EMAIL,
        {%elif company | lower == 'wagway' and sourcesystem | lower == 'hubspot_pawville' %}
        CAST(NULL AS VARCHAR) AS PROPERTY_CLUB_C,
        PROPERTY_GINGR_EMAIL,
        {%else%}
        CAST(NULL AS VARCHAR) AS PROPERTY_CLUB_C,
        CAST(NULL AS VARCHAR) AS GINGR_EMAIL,
        {%endif%}

        -- Lifecycle stage normalized to lowercase
        LOWER(TRIM(PROPERTY_LIFECYCLESTAGE)) AS PROPERTY_LIFECYCLESTAGE,

        CAST(TRIM(PROPERTY_HUBSPOT_OWNER_ID) AS INT) AS PROPERTY_HUBSPOT_OWNER_ID,

        -- Job title properly cased
        INITCAP(TRIM(PROPERTY_JOBTITLE)) AS PROPERTY_JOBTITLE,

        -- Cast and standardize dates
        TRY_TO_TIMESTAMP_NTZ(TRIM(PROPERTY_CREATEDATE)) AS PROPERTY_CREATEDATE,

        LOWER(TRIM(PROPERTY_HS_LEAD_STATUS)) AS PROPERTY_HS_LEAD_STATUS,

        -- Address cleanup
        INITCAP(TRIM(PROPERTY_ADDRESS)) AS PROPERTY_ADDRESS,
        INITCAP(TRIM(PROPERTY_CITY)) AS PROPERTY_CITY,
        INITCAP(TRIM(PROPERTY_STATE)) AS PROPERTY_STATE,
        INITCAP(TRIM(PROPERTY_COUNTRY)) AS PROPERTY_COUNTRY,

        REGEXP_REPLACE(TRIM(PROPERTY_FAX), '[^0-9]', '') AS PROPERTY_FAX,

        TRIM(PROPERTY_HS_TIMEZONE) AS PROPERTY_HS_TIMEZONE,

        {% if company | lower == 'amh' %}
            -- This column exists only for AMH
            TRIM(PROPERTY_MIDDLE_NAME) AS PROPERTY_MIDDLE_NAME,
        {%else%}
            CAST(NULL AS VARCHAR) AS PROPERTY_MIDDLE_NAME,
        {% endif %}

        _FIVETRAN_SYNCED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE,
        CAST(DBT_VALID_FROM AS TIMESTAMP_NTZ) AS DBT_VALID_FROM,
        CAST(DBT_VALID_TO AS TIMESTAMP_NTZ) AS DBT_VALID_TO,
        CASE WHEN DBT_VALID_TO IS NULL THEN 1 ELSE 0 END AS IS_ACTIVE

    FROM raw
)

SELECT *
FROM cleaned
