
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    
) }}

with source as (
    SELECT DISTINCT
        ABS(HASH(A.RECORDNO ,L.ENTITY)) AS DIM_ACCOUNT_ID,
        A.RECORDNO AS ACCOUNT_ID, 
        A.ACCOUNTNO AS ACCOUNT_NO, 
        A.TITLE AS ACCOUNT_TITLE,
        A.ACCOUNTTYPE AS ACCOUNTTYPE,
        A.NORMALBALANCE AS CREDIT_OR_DEBIT,
        LE.ENTITY_CODE AS SUBSIDIARY_ID, 
        LE.NAME AS SUBSIDIARY_NAME,
        LE.ENTITY AS SUBSIDIARY_FULL_NAME  

    FROM 
        {{ get_silver_source(company, 'sage_gl_account') }} A
        LEFT JOIN {{ get_silver_source(company, 'sage_gl_entry') }} GE ON GE.ACCOUNTKEY = A.RECORDNO 
        LEFT JOIN {{ get_silver_source(company, 'sage_location') }} L ON GE.LOCATIONKEY = L.RECORDNO
        LEFT JOIN {{ get_silver_source(company, 'sage_location_entity') }} LE  ON L.ENTITY = LE.ENTITY_CODE
    
)
select *
from source 