{% macro sf_canonical_lead(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'LEAD_ID',
        'OWNER_ID',
        'COMPANY',
        'FIRST_NAME',
        'LAST_NAME',
        'SALUTATION',
        'TITLE',
        'EMAIL',
        'PHONE',
        'MOBILE_PHONE',
        'WEBSITE',
        'LEAD_SOURCE',
        'STATUS',
        'RATING',
        'INDUSTRY',
        'NUMBER_OF_EMPLOYEES',
        'STREET',
        'CITY',
        'STATE',
        'POSTAL_CODE',
        'COUNTRY',
        'CONVERTED_DATE',
        'CONVERTED_ACCOUNT_ID',
        'CONVERTED_CONTACT_ID',
        'CONVERTED_OPPORTUNITY_ID',
        'IS_CONVERTED',
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
  'LEAD_ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
            'LEAD_ID' : 'ID',
            'OWNER_ID' : 'OWNER_ID',
            'COMPANY' : 'COMPANY',
            'FIRST_NAME' : 'FIRST_NAME',
            'LAST_NAME' : 'LAST_NAME',
            'SALUTATION' : 'SALUTATION',
            'TITLE' : 'TITLE',
            'EMAIL' : 'EMAIL',
            'PHONE' : 'PHONE',
            'MOBILE_PHONE' : 'MOBILE_PHONE',
            'WEBSITE' : 'WEBSITE',
            'LEAD_SOURCE' : 'LEAD_SOURCE',
            'STATUS' : 'STATUS',
            'RATING' : 'RATING',
            'INDUSTRY' : 'INDUSTRY',
            'NUMBER_OF_EMPLOYEES' : 'NUMBER_OF_EMPLOYEES',
            'STREET' : 'STREET',
            'CITY' : 'CITY',
            'STATE' : 'STATE',
            'POSTAL_CODE' : 'POSTAL_CODE',
            'COUNTRY' : 'COUNTRY',
            'CONVERTED_DATE' : 'CONVERTED_DATE',
            'CONVERTED_ACCOUNT_ID' : 'CONVERTED_ACCOUNT_ID',
            'CONVERTED_CONTACT_ID' : 'CONVERTED_CONTACT_ID',
            'CONVERTED_OPPORTUNITY_ID' : 'CONVERTED_OPPORTUNITY_ID',
            'IS_CONVERTED' : 'IS_CONVERTED',
            'CREATED_DATE' : 'CREATED_DATE',
            'CREATED_BY_ID' : 'CREATED_BY_ID',
            'LAST_MODIFIED_DATE' : 'LAST_MODIFIED_DATE',
            'LAST_MODIFIED_BY_ID' : 'LAST_MODIFIED_BY_ID',
            'DESCRIPTION' : 'DESCRIPTION'

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
