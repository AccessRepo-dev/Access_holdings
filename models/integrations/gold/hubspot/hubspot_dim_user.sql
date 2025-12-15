{% set company = var("company", "wagway") %}
{{ config(enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"] and var("company", "none") in ["wagway", "playfly"]) }}



{{ config(
    database = get_target_database(company),
    alias = 'dim_user',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['USER_ID']
) }}

SELECT
    ID_DATE_KEY,

    md5(   
        coalesce(nullif(cast(ID as string),''), '') || '|' ||
        coalesce('HUBSPOT','')
        ) as USER_ID,
    CONCAT(FIRST_NAME,LAST_NAME) AS NAME ,
    is_active,
    
    {% if company == "wagway" %}
        'HUBSPOT_PUPS' as SOURCE_SCHEMA,

    {%else%}

        CONCAT('HUBSPOT_','{{company | upper}}') as SOURCE_SCHEMA,

    {% endif %}
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE

FROM {{ get_silver_source(company , 'HUBSPOT_USERS') }} u

{% if company == 'wagway'%} 

UNION ALL 

SELECT
    ID_DATE_KEY,
    md5(   
        coalesce(nullif(cast(ID as string),''), '') || '|' ||
        coalesce('HUBSPOT_PAWVILLE','')
        ) as USER_ID,
    CONCAT(FIRST_NAME,LAST_NAME) AS NAME ,
    is_active,
    'HUBSPOT_PAWVILLE' AS SOURCE_SCHEMA,
    CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS GOLD_LOAD_DATE
FROM {{ get_silver_source(company, 'HUBSPOT_PAWVILLE_USERS') }} u
{% endif %}