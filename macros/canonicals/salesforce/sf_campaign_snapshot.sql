{% macro sf_canonical_campaign(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
'CAMPAIGN_ID',
'NAME',
'TYPE',
'STATUS',
'START_DATE',
'END_DATE',
'EXPECTED_REVENUE',
'BUDGETED_COST',
'ACTUAL_COST',
'NUMBER_SENT',
'OWNER_ID',
'DESCRIPTION',
'CREATED_DATE',
'LAST_MODIFIED_DATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
    'CAMPAIGN_ID':'VARCHAR(18)',
    'NAME':'VARCHAR(240)',
    'TYPE':'VARCHAR(765)',
    'STATUS':'VARCHAR(765)',
    'START_DATE':'TIMESTAMP_NTZ(9)',
    'END_DATE':'TIMESTAMP_NTZ(9)',
    'EXPECTED_REVENUE':'NUMBER(38,0)',
    'BUDGETED_COST':'NUMBER(38,0)',
    'ACTUAL_COST':'NUMBER(38,0)',
    'NUMBER_SENT':'FLOAT',
    'OWNER_ID':'VARCHAR(18)',
    'DESCRIPTION':'VARCHAR(96000)',
    'CREATED_DATE':'TIMESTAMP_NTZ(9)',
    'LAST_MODIFIED_DATE':'TIMESTAMP_NTZ(9)'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'salesforce': {
    'zeus': {
'CAMPAIGN_ID'        : 'ID',
    'NAME'               : 'NAME',
    'TYPE'               : 'TYPE',
    'STATUS'             : 'STATUS',
    'START_DATE'         : 'START_DATE',
    'END_DATE'           : 'END_DATE',
    'EXPECTED_REVENUE'   : 'EXPECTED_REVENUE',
    'BUDGETED_COST'      : 'BUDGETED_COST',
    'ACTUAL_COST'        : 'ACTUAL_COST',
    'NUMBER_SENT'        : 'NUMBER_SENT',
    'OWNER_ID'           : 'OWNER_ID',
    'DESCRIPTION'        : 'DESCRIPTION',
    'CREATED_DATE'       : 'CREATED_DATE',
    'LAST_MODIFIED_DATE' : 'LAST_MODIFIED_DATE'
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
