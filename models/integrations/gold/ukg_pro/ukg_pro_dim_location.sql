{% set company = var('company', 'playfly') | lower %}
{{ config(enabled = var('sourcesystem', 'ukg_pro') | lower == 'ukg_pro') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    alias = 'dim_location_hr',
    incremental_strategy = 'merge',
    unique_key = 'DIM_LOCATION_ID'
) }}

with source as (
    select

        ID AS DIM_LOCATION_ID,
        CITY,
        COUNTRY_CODE,
        STATE,
        ZIP_OR_POSTAL_CODE

    from {{ref('ukg_pro_location')}}
    WHERE IS_ACTIVE = True AND _FIVETRAN_DELETED = False

)
select *
from source