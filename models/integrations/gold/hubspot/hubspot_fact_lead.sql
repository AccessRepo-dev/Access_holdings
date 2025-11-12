{% set company = var('company') %}
{% set sourcesystem = var('sourcesystem') %}

{{ config(
    enabled = var('sourcesystem', 'none') == 'hubspot',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'HS_LEAD_ID',
    database = get_target_database(company),
    schema = 'gold',
    alias = 'fact_lead'
) }}

WITH lead_data AS (
    SELECT
        sl.HS_LEAD_ID,
        o.OWNER_ID AS owner_key,
        c.ID AS company_key,
        --sl.status,
        sl.PROPERTY_HS_LEAD_SOURCE AS source,
        dd1.date_key AS created_date_key,
        dd2.date_key AS LAST_MODIFIED_DATE,
        dd3.date_key AS converted_date_key,
        --CASE WHEN sl.status = 'Converted' THEN TRUE ELSE FALSE END AS is_converted,
        CURRENT_TIMESTAMP() AS gold_load_date
    FROM {{ ref('hubspot_lead') }} AS sl
    LEFT JOIN {{ ref('hubspot_dim_owner') }} AS o
        ON sl.PROPERTY_HUBSPOT_OWNER_ID = o.OWNER_ID
      -- AND o.is_current = TRUE
    LEFT JOIN {{ ref('hubspot_dim_company') }} AS c
        ON sl.PROPERTY_HUBSPOT_OWNER_ID = c.OWNER_ID
     --  AND c.is_current = TRUE
    LEFT JOIN {{ ref('hubspot_dim_date') }} AS dd1
        ON dd1.date_value = CAST(sl.PROPERTY_HS_CREATEDATE AS DATE)
    LEFT JOIN {{ ref('hubspot_dim_date') }} AS dd2
        ON dd2.date_value = CAST(sl.PROPERTY_HS_LASTMODIFIEDDATE AS DATE)
    LEFT JOIN {{ ref('hubspot_dim_date') }} AS dd3
        ON dd3.date_value = CAST(sl.PROPERTY_HS_LASTMODIFIEDDATE AS DATE) -- placeholder for converted date
)

SELECT
    HS_LEAD_ID,
    OWNER_KEY,
    COMPANY_KEY,
    --STATUS,
    SOURCE,
    CREATED_DATE_KEY,
    LAST_MODIFIED_DATE,
    CONVERTED_DATE_KEY,
    --IS_CONVERTED,
    GOLD_LOAD_DATE
FROM lead_data
