{{
    config(
        materialized="incremental",
        unique_key="EMPLOYEE_ID",
        incremental_strategy="merge",
    )
}}

select
    accountnumber as account_number,
    cast(class as int) as class_id,
    cast(datecreated as date) as date_created,
    cast(currency as int) as currency,
    cast(department as int) as department_id,
    email as email,
    cast(id as int) as employee_id,
    employeetype as employee_type_id,
    entityid as entity_id,
    isinactive as is_inactive,
    jobdescription as job_description,
    cast(lastmodifieddate as date) as last_modified_date,
    cast(location as int) as location_id,
    cast(subsidiary as int) as subsidiary,
    title as title,
    current_timestamp() as silver_load_date
from {{ source("wagway_netsuite", "EMPLOYEE") }}
