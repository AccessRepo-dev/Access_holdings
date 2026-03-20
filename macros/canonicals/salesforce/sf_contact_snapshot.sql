{% macro sf_canonical_contact(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'CONTACT_ID',
        'ACCOUNT_ID',
        'NAME',
        'FIRST_NAME',
        'LAST_NAME',
        'SALUTATION',
        'TITLE',
        'DEPARTMENT',
        'EMAIL',
        'PHONE',
        'MOBILE_PHONE',
        'MAILING_STREET',
        'MAILING_CITY',
        'MAILING_STATE',
        'MAILING_POSTAL_CODE',
        'MAILING_COUNTRY',
        'LEAD_SOURCE',
        'OWNER_ID',
        'CREATED_DATE',
        'CREATED_BY_ID',
        'LAST_MODIFIED_DATE',
        'LAST_MODIFIED_BY_ID',
        'DESCRIPTION'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'CONTACT_ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
        'CONTACT_ID'           : 'ID',
        'ACCOUNT_ID'           : 'ACCOUNT_ID',
        'NAME'                 : 'NAME',
        'FIRST_NAME'           : 'FIRST_NAME',
        'LAST_NAME'            : 'LAST_NAME',
        'SALUTATION'           : 'SALUTATION',
        'TITLE'                : 'TITLE',
        'DEPARTMENT'           : 'DEPARTMENT',
        'EMAIL'                : 'EMAIL',
        'PHONE'                : 'PHONE',
        'MOBILE_PHONE'         : 'MOBILE_PHONE',
        'MAILING_STREET'       : 'MAILING_STREET',
        'MAILING_CITY'         : 'MAILING_CITY',
        'MAILING_STATE'        : 'MAILING_STATE',
        'MAILING_POSTAL_CODE'  : 'MAILING_POSTAL_CODE',
        'MAILING_COUNTRY'      : 'MAILING_COUNTRY',
        'LEAD_SOURCE'          : 'LEAD_SOURCE',
        'OWNER_ID'             : 'OWNER_ID',
        'CREATED_DATE'         : 'CREATED_DATE',
        'CREATED_BY_ID'        : 'CREATED_BY_ID',
        'LAST_MODIFIED_DATE'   : 'LAST_MODIFIED_DATE',
        'LAST_MODIFIED_BY_ID'  : 'LAST_MODIFIED_BY_ID'
    }
  }

} %}

{# -------------------------------
   Validate source
-------------------------------- #}
{# -------------------------------
   Resolve company mapping safely
-------------------------------- #}
{% if source == 'salesforce' %}
  {% set company_mapping = mappings.get(source, {}).get(company, {}) %}
{% else %}
  {# Non-salesforce source → bypass safely #}
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
