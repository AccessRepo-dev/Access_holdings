{% macro hs_canonical_deal_pipeline_stage(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
    'STAGE_ID',
    'LABEL',
    'PIPELINE_ID',
    'PROBABILITY',
    'IS_CLOSED',
    'WRITE_PERMISSIONS',
    'DISPLAY_ORDER',
    'CREATED_AT',
    'UPDATED_AT'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
  'STAGE_ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
            'STAGE_ID'          : 'STAGE_ID',
            'LABEL'             : 'LABEL',
            'PIPELINE_ID'       : 'PIPELINE_ID',
            'PROBABILITY'       : 'PROBABILITY',
            'IS_CLOSED'         : 'IS_CLOSED',
            'WRITE_PERMISSIONS' : 'WRITE_PERMISSIONS',
            'DISPLAY_ORDER'     : 'DISPLAY_ORDER',
            'CREATED_AT'        : 'CREATED_AT',
            'UPDATED_AT'        : 'UPDATED_AT'

    },
    'amh': {
            'STAGE_ID'          : 'STAGE_ID',
            'LABEL'             : 'LABEL',
            'PIPELINE_ID'       : 'PIPELINE_ID',
            'PROBABILITY'       : 'PROBABILITY',
            'IS_CLOSED'         : 'IS_CLOSED',
            'WRITE_PERMISSIONS' : 'WRITE_PERMISSIONS',
            'DISPLAY_ORDER'     : 'DISPLAY_ORDER',
            'CREATED_AT'        : 'CREATED_AT',
            'UPDATED_AT'        : 'UPDATED_AT'
    },
    'playfly': {
            'STAGE_ID'          : 'STAGE_ID',
            'LABEL'             : 'LABEL',
            'PIPELINE_ID'       : 'PIPELINE_ID',
            'PROBABILITY'       : 'PROBABILITY',
            'IS_CLOSED'         : 'IS_CLOSED',
            'WRITE_PERMISSIONS' : 'WRITE_PERMISSIONS',
            'DISPLAY_ORDER'     : 'DISPLAY_ORDER',
            'CREATED_AT'        : 'CREATED_AT',
            'UPDATED_AT'        : 'UPDATED_AT'
    }
  },

  'hubspot_pawville': {
    'wagway': {
            'STAGE_ID'          : 'STAGE_ID',
            'LABEL'             : 'LABEL',
            'PIPELINE_ID'       : 'PIPELINE_ID',
            'PROBABILITY'       : 'PROBABILITY',
            'IS_CLOSED'         : 'IS_CLOSED',
            'WRITE_PERMISSIONS' : 'WRITE_PERMISSIONS',
            'DISPLAY_ORDER'     : 'DISPLAY_ORDER',
            'CREATED_AT'        : 'CREATED_AT',
            'UPDATED_AT'        : 'UPDATED_AT'
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
