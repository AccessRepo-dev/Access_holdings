{% macro sf_canonical_case(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
    'CASE_ID',
    'ACCOUNT_ID',
    'CONTACT_ID',
    'OWNER_ID',
    'STATUS',
    'ORIGIN',
    'REASON',
    'SUBJECT',
    'DESCRIPTION',
    'IS_CLOSED',
    'CLOSED_DATE',
    'LAST_MODIFIED_DATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'CASE_ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
        'CASE_ID'             : 'ID',
        'ACCOUNT_ID'          : 'ACCOUNT_ID',
        'CONTACT_ID'          : 'CONTACT_ID',
        'OWNER_ID'            : 'OWNER_ID',
        'STATUS'              : 'STATUS',
        'ORIGIN'              : 'ORIGIN',
        'REASON'              : 'REASON',
        'SUBJECT'             : 'SUBJECT',
        'DESCRIPTION'         : 'DESCRIPTION',
        'IS_CLOSED'           : 'IS_CLOSED',
        'CLOSED_DATE'         : 'CLOSED_DATE',
        'LAST_MODIFIED_DATE'  : 'LAST_MODIFIED_DATE'

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
