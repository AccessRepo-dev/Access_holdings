{% set company = var('company') %}

{{ config(
    database = get_target_database(company),
    alias = 'dim_ticket',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['TICKET_ID','SOURCE_SCHEMA']
) }}

SELECT
    TICKET_ID , 
    DESCRIPTION,  
    CREATED_DATE,  
    CLOSED_DATE,  
    PIPELINE_ID,  
    PIPELINE_STAGE_ID,  
    TICKET_PRIORITY , 
    OBJECT_SOURCE,  
    _FIVETRAN_SYNCED
    'HUBSPOT' AS SOURCE_SCHEMA
FROM {{ get_silver_source(company , 'HUBSPOT_TICKET') }} 




