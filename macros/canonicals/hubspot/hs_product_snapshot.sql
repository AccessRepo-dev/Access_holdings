{% macro hs_canonical_product(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'PRODUCT_ID',
        'PRODUCT_NAME',
        'PROPERTY_DESCRIPTION',
        'PROPERTY_FAMILY',
        'PORTAL_ID',
        'PRICING_MODEL',
        'PRODUCT_STATUS',
        'PRODUCT_TYPE',
        'PROPERTY_HS_FOLDER_ID',
        'PRICE',
        'CREATED_AT',
        'UPDATED_AT'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
        'PRODUCT_ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
            'PRODUCT_ID'        : 'ID',
            'PRODUCT_NAME'      : 'PROPERTY_NAME',
            'PROPERTY_DESCRIPTION' : 'PROPERTY_DESCRIPTION',
            'PROPERTY_FAMILY'   : 'PROPERTY_FAMILY',
            'PRICE'             : 'PROPERTY_PRICE',
            'CREATED_AT'        : 'PROPERTY_HS_CREATEDATE',
            'UPDATED_AT'        : 'PROPERTY_HS_LASTMODIFIEDDATE'
    },
    'amh': {
            'PRODUCT_ID'        : 'ID',
            'PRODUCT_NAME'      : 'PROPERTY_NAME',
            'PORTAL_ID'         : 'PORTAL_ID',
            'PRICING_MODEL'     : 'PROPERTY_HS_PRICING_MODEL',
            'PRODUCT_STATUS'    : 'PROPERTY_HS_STATUS',
            'PRODUCT_TYPE'      : 'PROPERTY_HS_PRODUCT_TYPE',
            'PROPERTY_HS_FOLDER_ID' : 'PROPERTY_HS_FOLDER_ID',
            'PRICE'             : 'PROPERTY_PRICE',
            'CREATED_AT'        : 'PROPERTY_CREATEDATE',
            'UPDATED_AT'        : 'PROPERTY_HS_LASTMODIFIEDDATE'

    },
    'playfly': {
            'PRODUCT_ID'        : 'ID',
            'PRODUCT_NAME'      : 'PROPERTY_NAME',
            'PROPERTY_DESCRIPTION' : 'PROPERTY_DESCRIPTION',
            'PROPERTY_FAMILY'   : 'PROPERTY_FAMILY',
            'PORTAL_ID'         : 'PORTAL_ID',
            'PRICING_MODEL'     : 'PROPERTY_HS_PRICING_MODEL',
            'PRODUCT_STATUS'    : 'PROPERTY_HS_STATUS',
            'PRODUCT_TYPE'      : 'PROPERTY_PRODUCT_CATEGORY',
            'PRICE'             : 'PROPERTY_PRICE',
            'CREATED_AT'        : 'PROPERTY_CREATEDATE',
            'UPDATED_AT'        : 'PROPERTY_HS_LASTMODIFIEDDATE'
    }
  },

  'hubspot_pawville': {
    'wagway': {
            'PRODUCT_ID'        : 'ID',
            'PRODUCT_NAME'      : 'PROPERTY_NAME',
            'PROPERTY_DESCRIPTION' : 'PROPERTY_DESCRIPTION',
            'PROPERTY_FAMILY'   : 'PROPERTY_FAMILY',
            'PRICE'             : 'PROPERTY_PRICE',
            'CREATED_AT'        : 'PROPERTY_HS_CREATEDATE',
            'UPDATED_AT'        : 'PROPERTY_HS_LASTMODIFIEDDATE'

    }
  }

} %}

{# -------------------------------
   Validate source
-------------------------------- #}
{# -------------------------------
   Resolve company mapping safely
-------------------------------- #}
{% if source in ['hubspot_pawville', 'hubspot'] %}
  {% set company_mapping = mappings.get(source, {}).get(company, {}) %}
{% else %}
  {# Non-hubspot source → bypass safely #}
  {% set company_mapping = {} %}
{% endif %}


{# -------------------------------
   Generate SELECT list (NULL-safe)
-------------------------------- #}
{% set select_cols = [] %}

{% for col in canonical_cols %}
  {% if col in company_mapping %}
    {% do select_cols.append(company_mapping[col] ~ ' AS ' ~ col) %}
  {% else %}
    {% do select_cols.append(
      'CAST(NULL AS ' ~ column_types.get(col, 'VARCHAR') ~ ') AS ' ~ col
    ) %}
  {% endif %}
{% endfor %}

{{ return(select_cols | join(',\n')) }}

{% endmacro %}
