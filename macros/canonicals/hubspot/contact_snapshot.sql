{% macro crm_contact_snapshot(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
  'ID',
  'PROPERTY_NAME',
  'PROPERTY_DOMAIN',
  'PROPERTY_PHONE',
  'PROPERTY_ADDRESS',
  'PROPERTY_CITY',
  'PROPERTY_STATE',
  'PROPERTY_COUNTRY',
  'PROPERTY_INDUSTRY',
  'PROPERTY_HUBSPOT_OWNER_ID',
  'PROPERTY_ANNUALREVENUE',
  'PROPERTY_CREATEDATE',
  'PROPERTY_HS_LASTMODIFIEDDATE',
  'PROPERTY_COMPANY_TYPE',
  'PROPERTY_NUMBEROFEMPLOYEES'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'ID': 'NUMBER',
  'PROPERTY_HUBSPOT_OWNER_ID': 'NUMBER',
  'PROPERTY_ANNUALREVENUE': 'NUMBER',
  'PROPERTY_NUMBEROFEMPLOYEES': 'NUMBER',
  'PROPERTY_CREATEDATE': 'TIMESTAMP_NTZ',
  'PROPERTY_HS_LASTMODIFIEDDATE': 'TIMESTAMP_NTZ'
} %}

{# -------------------------------
   Source + contact mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
      'ID': 'ID',
      'PROPERTY_NAME': 'PROPERTY_NAME',
      'PROPERTY_DOMAIN': 'PROPERTY_DOMAIN',
      'PROPERTY_PHONE': 'PROPERTY_PHONE',
      'PROPERTY_ADDRESS': 'PROPERTY_ADDRESS',
      'PROPERTY_CITY': 'PROPERTY_CITY',
      'PROPERTY_STATE': 'PROPERTY_STATE',
      'PROPERTY_COUNTRY': 'PROPERTY_COUNTRY',
      'PROPERTY_INDUSTRY': 'PROPERTY_INDUSTRY',
      'PROPERTY_HUBSPOT_OWNER_ID': 'PROPERTY_HUBSPOT_OWNER_ID',
      'PROPERTY_ANNUALREVENUE': 'PROPERTY_ANNUALREVENUE',
      'PROPERTY_CREATEDATE': 'PROPERTY_CREATEDATE',
      'PROPERTY_HS_LASTMODIFIEDDATE': 'PROPERTY_HS_LASTMODIFIEDDATE',
      'PROPERTY_COMPANY_TYPE': 'PROPERTY_COMPANY_TYPE',
      'PROPERTY_NUMBEROFEMPLOYEES': 'PROPERTY_NUMBEROFEMPLOYEES'
    }
  },

  'hubspot_pawville': {
    'wagway': {
      'ID': 'ID',
      'PROPERTY_NAME': 'PROPERTY_NAME',
      'PROPERTY_CREATEDATE': 'PROPERTY_CREATEDATE',
      'PROPERTY_HS_LASTMODIFIEDDATE': 'PROPERTY_HS_LASTMODIFIEDDATE',
      'PROPERTY_NUMBEROFEMPLOYEES': 'PROPERTY_NUMBEROFEMPLOYEES'
    }
  }

} %}

{# -------------------------------
   Validate source
-------------------------------- #}
{% if source not in mappings %}
  {{ exceptions.raise_compiler_error(
      'No CRM mapping defined for source: ' ~ source
  ) }}
{% endif %}

{% set contact_mapping = mappings[source].get(company, {}) %}

{# -------------------------------
   Generate SELECT list (NULL-safe)
-------------------------------- #}
{% set select_cols = [] %}

{% for col in canonical_cols %}
  {% if col in contact_mapping %}
    {% do select_cols.append(contact_mapping[col] ~ ' AS ' ~ col) %}
  {% else %}
    {% do select_cols.append(
      'CAST(NULL AS ' ~ column_types.get(col, 'VARCHAR') ~ ') AS ' ~ col
    ) %}
  {% endif %}
{% endfor %}

{{ return(select_cols | join(',\n')) }}

{% endmacro %}
