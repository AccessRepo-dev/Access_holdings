{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem  = var('sourcesystem', 'Unknown source') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'location',
    incremental_strategy = 'merge',
    unique_key = 'ID'
) }}

with source_data as (
    select *
    {% if company == 'wagway'%}
    from {{ get_raw_source(company, sourcesystem, 'CUSTOMRECORD_CSEG_CP_STORE_LOC') }}
    {% else %}
    from {{ get_raw_source(company, sourcesystem, 'LOCATION') }}
    {% endif %}
),

cleaned as (
    select
        TRY_CAST(s.ID AS INT) AS ID,
        TRIM(s.NAME) AS NAME,
        
        a.NAME AS PARENT_NAME,
        {% if company == 'wagway'  %}
            TRIM(s.NAME) AS FULLNAME,
            COALESCE(s.PARENT,-1) AS PARENT,
            null AS LOCATIONTYPE,
            CAST(null AS INT) AS SUBSIDIARY,
            CAST(s.LASTMODIFIED AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        {% else %}
            TRIM(s.FULLNAME) AS FULLNAME,
            TRY_CAST(s.PARENT AS INT) AS PARENT,
            TRIM(s.LOCATIONTYPE) AS LOCATIONTYPE,
            TRY_CAST(s.SUBSIDIARY AS INT) AS SUBSIDIARY,
            CAST(s.LASTMODIFIEDDATE AS TIMESTAMP_NTZ) AS LASTMODIFIEDDATE,
        {% endif %}
        CAST(
            CASE 
                WHEN s.ISINACTIVE = 'T' THEN TRUE
                WHEN s.ISINACTIVE = 'F' THEN FALSE
                ELSE NULL
            END AS BOOLEAN
        ) AS ISINACTIVE,
        s._FIVETRAN_DELETED AS _FIVETRAN_DELETED,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS SILVER_LOAD_DATE
    from source_data s
    {% if company == 'wagway'%}
    LEFT JOIN {{ get_raw_source(company, sourcesystem, 'CUSTOMRECORD_CSEG_CP_STORE_LOC') }} a
    ON s.PARENT = a.ID
    {% endif %}
)

select
    *
from cleaned