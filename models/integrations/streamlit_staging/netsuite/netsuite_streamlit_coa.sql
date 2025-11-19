{% set company = var('company', 'Unknown company') | lower %}
{% set sourcesystem = var('sourcesystem', 'Unknown source') | lower %}
{% set src = var('company') ~ '_' ~ var('sourcesystem') ~ '_raw'%}
{{ config(enabled = var('sourcesystem', 'none') == 'netsuite') }}



{{ config(
    materialized = 'incremental',
    alias = company ~ '_COA_MAPPING',
    incremental_strategy = 'merge',
    unique_key = 'COA_ID'
) }}

    SELECT 
    DISTINCT
    hash(
            coalesce(tal.account, 0),
            coalesce(tl.subsidiary, 0),
            coalesce(tl.class, 0),
            coalesce(tl.cseg_cp_store_loc, 0),
            coalesce(tl.department, 0),
            coalesce(tl.cseg1, 0)
    ) AS COA_ID,
    COALESCE(tal.ACCOUNT, 0) AS ACCOUNT_ID,
    COALESCE(tl.SUBSIDIARY, 0) AS SUBSIDIARY_ID,
    COALESCE(tl.CLASS, 0) AS CLASS_ID,
    COALESCE(tl.CSEG_CP_STORE_LOC, 0) AS LOCATION_ID,
    COALESCE(tl.DEPARTMENT, 0) AS DEPARTMENT_ID,
    COALESCE(tl.CSEG1, 0) AS ADJUSTMENT_ID,
    
    COALESCE(l.NAME, 'Unknown') AS LOCATION_NAME,
    COALESCE(s.NAME, 'Unknown') AS SUBSIDIARY_NAME,
    COALESCE(a.FULLNAME, 'Unknown') AS ACCOUNT_NAME,
    COALESCE(c.NAME, 'Unknown') AS CLASS_NAME,
    COALESCE(d.FULLNAME, 'Unknown') AS DEPARTMENT_NAME,
    COALESCE(ad.name, 'Unknown') AS ADJUSTMENT_NAME,
    NULL AS METRIC_L1,
    NULL AS METRIC_L2,
    NULL AS METRIC_L3,
    NULL AS METRIC_L4,
    NULL AS METRIC_L5,
    NULL AS METRIC_L6,
    NULL AS CASHFLOW_L1,
    NULL AS CASHFLOW_L2,
    NULL AS CASHFLOW_L3,
    NULL AS IS_BS,
    NULL AS DEBT_MAPPING,
    CURRENT_TIMESTAMP AS DATA_LOADED_AT 


FROM {{ source(src, 'TRANSACTIONLINE') }} tl
LEFT JOIN {{ source(src, 'TRANSACTION') }} t ON t.ID = tl.TRANSACTION
LEFT JOIN {{ source(src, 'TRANSACTIONACCOUNTINGLINE') }} tal ON tl.TRANSACTION = tal.TRANSACTION AND tl.ID = tal.TRANSACTIONLINE
LEFT JOIN {{ source(src, 'ACCOUNT') }} a ON a.ID = tal.ACCOUNT
LEFT JOIN {{ source(src, 'CLASSIFICATION') }} c ON c.ID = COALESCE(tl.CLASS, 0)
LEFT JOIN {{ source(src, 'CUSTOMRECORD_CSEG_CP_STORE_LOC') }} l ON l.ID = COALESCE(t.CSEG_CP_STORE_LOC, 0)
LEFT JOIN {{ source(src, 'SUBSIDIARY') }} s ON s.ID = COALESCE(tl.SUBSIDIARY, 0)
LEFT JOIN {{ source(src, 'CUSTOMRECORD_CSEG1') }} ad ON COALESCE(t.CSEG1, 0) = ad.ID
LEFT JOIN {{ source(src, 'DEPARTMENT') }} d ON d.ID = COALESCE(tl.DEPARTMENT, 0)

{% if is_incremental() %}
    where Coa_id not in (
        select Coa_id
        from {{ this }}
    )
{% endif %}

