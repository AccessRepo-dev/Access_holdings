{% macro sf_canonical_user(company, sourcesystem) %}

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
        'USERNAME',
        'NAME',
        'EMAIL',
        'ALIAS',
        'FIRST_NAME',
        'LAST_NAME',
        'USER_IS_ACTIVE',
        'USER_ROLE_ID',
        'PROFILE_ID',
        'TITLE',
        'DEPARTMENT',
        'MANAGER_ID',
        'CREATED_DATE',
        'LAST_LOGIN_DATE',
        'LAST_MODIFIED_DATE',
        'TIME_ZONE_SID_KEY',
        'LOCALE_SID_KEY',
        'LANGUAGE_LOCALE_KEY'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'ID': 'VARCHAR(18)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
            'ID'                     : 'ID',
            'USERNAME'               : 'USERNAME',
            'NAME'                   : 'NAME',
            'EMAIL'                  : 'EMAIL',
            'ALIAS'                  : 'ALIAS',
            'FIRST_NAME'             : 'FIRST_NAME',
            'LAST_NAME'              : 'LAST_NAME',
            'USER_IS_ACTIVE'         : 'IS_ACTIVE',
            'USER_ROLE_ID'           : 'USER_ROLE_ID',
            'PROFILE_ID'             : 'PROFILE_ID',
            'TITLE'                  : 'TITLE',
            'DEPARTMENT'             : 'DEPARTMENT',
            'MANAGER_ID'             : 'MANAGER_ID',
            'CREATED_DATE'           : 'CREATED_DATE',
            'LAST_LOGIN_DATE'        : 'LAST_LOGIN_DATE',
            'LAST_MODIFIED_DATE'     : 'LAST_MODIFIED_DATE',
            'TIME_ZONE_SID_KEY'      : 'TIME_ZONE_SID_KEY',
            'LOCALE_SID_KEY'         : 'LOCALE_SID_KEY',
            'LANGUAGE_LOCALE_KEY'    : 'LANGUAGE_LOCALE_KEY'

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
