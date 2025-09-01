{{ config(
    materialized = 'incremental',
    unique_key = 'INTERNAL_ENTITY_ID',
    incremental_strategy = 'merge'
) }}

SELECT
    CAST(contact AS INT) AS CONTACT_ID,
    CAST(customer AS INT) AS CUSTOMER_ID,
    CAST(datecreated AS DATE) AS DATE_CREATED,
    email AS EMAIL,
    CAST(employee AS INT) AS EMPLOYEE_ID,
    entityid AS ENTITY_ID,
    CAST(entitynumber AS INT) AS ENTITY_NUMBER,
    entitytitle AS ENTITY_TITLE,
    firstname AS FIRST_NAME,
    CAST("GROUP" AS INT) AS GROUP_ID,
    CAST(id AS INT) AS INTERNAL_ENTITY_ID,
    isinactive AS IS_INACTIVE,
    isperson AS IS_PERSON,
    CAST(lastmodifieddate AS DATE) AS LAST_MODIFIED_DATE,
    lastname AS LAST_NAME,
    CAST(parent AS INT) AS PARENT_ID,
    "TYPE" AS ENTITY_TYPE,
    CAST(vendor AS INT) AS VENDOR_ID,
    CURRENT_TIMESTAMP()::TIMESTAMP AS SILVER_LOAD_DATE
FROM {{ source('wagway_netsuite', 'ENTITY') }}
