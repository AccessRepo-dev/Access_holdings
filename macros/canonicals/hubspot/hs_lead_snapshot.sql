{% macro hs_canonical_lead(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'HS_LEAD_ID',
        'PROPERTY_HUBSPOT_OWNER_ID',
        'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME',
        'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME',
        'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL',
        'PROPERTY_HS_LEAD_SOURCE',
        'PROPERTY_HS_CREATEDATE',
        'PROPERTY_HS_LASTMODIFIEDDATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
        'HS_LEAD_ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
            'HS_LEAD_ID'                                   : 'ID',
            'PROPERTY_HUBSPOT_OWNER_ID'                   : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME'    : 'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME'     : 'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL'        : 'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL',
            'PROPERTY_HS_LEAD_SOURCE'                     : 'PROPERTY_HS_LEAD_SOURCE',
            'PROPERTY_HS_CREATEDATE'                      : 'PROPERTY_HS_CREATEDATE',
            'PROPERTY_HS_LASTMODIFIEDDATE'                : 'PROPERTY_HS_LASTMODIFIEDDATE'
    },
    'amh': {
            'HS_LEAD_ID'                                   : 'ID',
            'PROPERTY_HUBSPOT_OWNER_ID'                   : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME'    : 'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME'     : 'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL'        : 'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL',
            'PROPERTY_HS_LEAD_SOURCE'                     : 'PROPERTY_HS_LEAD_SOURCE',
            'PROPERTY_HS_CREATEDATE'                      : 'PROPERTY_HS_CREATEDATE',
            'PROPERTY_HS_LASTMODIFIEDDATE'                : 'PROPERTY_HS_LASTMODIFIEDDATE'

    },
    'playfly': {
            'HS_LEAD_ID'                                   : 'ID',
            'PROPERTY_HUBSPOT_OWNER_ID'                   : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME'    : 'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME'     : 'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL'        : 'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL',
            'PROPERTY_HS_LEAD_SOURCE'                     : 'PROPERTY_HS_LEAD_SOURCE',
            'PROPERTY_HS_CREATEDATE'                      : 'PROPERTY_HS_CREATEDATE',
            'PROPERTY_HS_LASTMODIFIEDDATE'                : 'PROPERTY_HS_LASTMODIFIEDDATE'

    }
  },

  'hubspot_pawville': {
    'wagway': {
            'HS_LEAD_ID'                                   : 'ID',
            'PROPERTY_HUBSPOT_OWNER_ID'                   : 'PROPERTY_HUBSPOT_OWNER_ID',
            'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME'    : 'PROPERTY_HS_ASSOCIATED_CONTACT_FIRSTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME'     : 'PROPERTY_HS_ASSOCIATED_CONTACT_LASTNAME',
            'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL'        : 'PROPERTY_HS_ASSOCIATED_CONTACT_EMAIL',
            'PROPERTY_HS_LEAD_SOURCE'                     : 'PROPERTY_HS_LEAD_SOURCE',
            'PROPERTY_HS_CREATEDATE'                      : 'PROPERTY_HS_CREATEDATE',
            'PROPERTY_HS_LASTMODIFIEDDATE'                : 'PROPERTY_HS_LASTMODIFIEDDATE'

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
