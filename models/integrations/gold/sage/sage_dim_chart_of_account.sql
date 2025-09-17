
{% set company = var('company', 'Unknown company') | lower %}
{{ config(enabled = var('sourcesystem', 'none') == 'sage') }}

{{ config(
    database = get_target_database(company),
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'DIM_ACCOUNT_ID'
) }}

with ACCOUNT_LOCATION AS 
(    SELECT DISTINCT 
            ACCOUNTKEY,
            LOCATIONKEY
    FROM {{ get_silver_source(company, 'sage_gl_entry') }}
),
source as (
    SELECT 

    
        -- Primary Key
        RECORDNO AS DIM_CHART_OF_ACCOUNT_ID,
 
        -- Core Identifiers
        al.ACCOUNTKEY AS ACCOUNT_ID,
        ACCOUNTNO AS ACCOUNT_NUMBER,
        GLACCTGRPKEY AS ACCOUNT_GROUP_KEY,
        LOCATIONKEY AS DIM_LOCATION_ID,
        -- Descriptions
        ACCOUNTTITLE AS ACCOUNT_TITLE,
        
        ACCOUNTTYPE AS ACCOUNT_TYPE,
        ACCOUNTNORMALBALANCE AS ACCOUNT_NORMAL_BALANCE,

        GLACCTGRPNAME AS ACCOUNT_GROUP_NAME,
        GLACCTGRPTITLE AS ACCOUNT_GROUP_TITLE,
        GLACCTGRPMEMBERTYPE AS ACCOUNT_GROUP_MEMBER_TYPE,
        GLACCTGRPHOWCREATED AS ACCOUNT_GROUP_HOW_CREATED,
        GLACCTGRPNORMALBALANCE AS ACCOUNT_GROUP_NORMAL_BALANCE,

        -- Metadata
        _FIVETRAN_SYNCED AS FIVETRAN_SYNCED_AT,

    FROM {{ get_silver_source(company, 'sage_gl_acct_grp_hierarchy') }} h
    LEFT JOIN ACCOUNT_LOCATION al ON al.ACCOUNTKEY = h.ACCOUNTKEY
    
    {% if is_incremental() %}
    and _FIVETRAN_SYNCED > (
        SELECT coalesce(max(FIVETRAN_SYNCED_AT), '1900-01-01')
        FROM {{ this }}
    )
    {% endif %}
)
SELECT *
FROM source
