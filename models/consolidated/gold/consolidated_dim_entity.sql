{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ENTITY_ID','SOURCESYSTEM','COMPANY']
) }}

select
    ENTITY_ID,
    INTERNAL_ENTITY_ID,
    ENTITY_NUMBER,
    ENTITY_TITLE,
    FIRST_NAME,
    LAST_NAME,
    ENTITY_TYPE,
    IS_PERSON,
    CONTACT_ID,
    EMPLOYEE_ID,
    CUSTOMER_ID,
    DATE_CREATED,
    EMAIL,
    GROUP_ID,
    IS_INACTIVE,
    LAST_MODIFIED_DATE,
    PARENT_ID,
    VENDOR_ID,
    'NETSUITE' AS SOURCESYSTEM,
    'WAGWAY' AS COMPANY,
     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_WAGWAY', 'wagway_dev') }}.gold.NETSUITE_DIM_ENTITY


union all

select
    ENTITY_ID,
    INTERNAL_ENTITY_ID,
    ENTITY_NUMBER,
    ENTITY_TITLE,
    FIRST_NAME,
    LAST_NAME,
    ENTITY_TYPE,
    IS_PERSON,
    CONTACT_ID,
    EMPLOYEE_ID,
    CUSTOMER_ID,
    DATE_CREATED,
    EMAIL,
    GROUP_ID,
    IS_INACTIVE,
    LAST_MODIFIED_DATE,
    PARENT_ID,
    VENDOR_ID,
    'NETSUITE' AS SOURCESYSTEM,
    'PLAYFLY' AS COMPANY,
     CURRENT_TIMESTAMP()::TIMESTAMP_NTZ AS CONSOLIDATED_GOLD_LOAD_DATE
from {{ env_var('DBT_PLAYFLY', 'playfly_dev') }}.gold.NETSUITE_DIM_ENTITY

