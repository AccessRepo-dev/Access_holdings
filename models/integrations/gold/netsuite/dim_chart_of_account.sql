{% set company = var('company', 'Unknown company') | lower %}

{{ config(
    database = get_target_database(company),
    materialized = 'table'
) }}

with source as (
    select
    DESCRIPTION AS ACCOUNT_DESCRIPTION,
    ID AS ACCOUNT_ID,
    FULLNAME AS ACCOUNT_NAME,
    ACCTNUMBER AS ACCOUNT_NUMBER,
    PARENT AS ACCOUNT_PARENT_ID,
    SUBSIDIARY AS ACCOUNT_SUBSIDIARY_ID,
    ACCTTYPE AS ACCOUNT_TYPE,
    FULLNAME AS CLASS_FULL_NAME,
    CLASS AS CLASS_ID,
    NAME AS CLASS_NAME,
    PARENT AS CLASSIFICATION_PARENT,
     null  AS CONSOLIDATED_EXCHANGE_RATE_UNIQUE_ID,
    CURRENCY AS CURRENCY_ID,
    DEPARTMENT AS DEPARTMENT_ID,
    ACCOUNTSEARCHDISPLAYNAME AS DISPLAY_NAME,
    DISPLAYNAMEWITHHIERARCHY AS DISPLAY_NAME_WITH_HIERARCHY,
    LOCATION AS LOCATION_ID,
    PARENT AS SUBSIDARY_PARENT_ID,
    FULLNAME AS SUBSIDIARY_FULL_NAME,
    SUBSIDIARY AS SUBSIDIARY_ID,
    NAME AS SUBSIDIARY_NAME
    from {{ get_silver_source(company, 'netsuite_account') }} a
    left join  {{ get_silver_source(company, 'netsuite_subsidiary') }} s ON a.SUBSIDIARY_ID = s.ID
    where (_fivetran_deleted is null or _fivetran_deleted = false)
)
select *
from source
