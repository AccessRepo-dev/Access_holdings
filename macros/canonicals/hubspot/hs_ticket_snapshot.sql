{% macro hs_canonical_ticket(company, sourcesystem) %}

{# -------------------------------
   Normalize inputs
-------------------------------- #}
{% set company = company | lower %}
{% set source = sourcesystem | lower %}

{# -------------------------------
   Canonical column contract
-------------------------------- #}
{% set canonical_cols = [
        'TICKET_ID',
        'PROPERTY_HS_TICKET_ID',
        'CREATED_DATE',
        'PIPELINE_ID',
        'PIPELINE_STAGE_ID',
        'OBJECT_SOURCE',
        'PROPERTY_HS_LASTMODIFIEDDATE'
] %}

{# -------------------------------
   Column data types (for NULLs)
-------------------------------- #}
{% set column_types = {
        'TICKET_ID': 'NUMBER'
} %}

{# -------------------------------
   Source + company mappings
-------------------------------- #}
{% set mappings = {

  'hubspot': {
    'wagway': {
            'TICKET_ID'                     : 'ID',
            'PROPERTY_HS_TICKET_ID'         : 'PROPERTY_HS_TICKET_ID',
            'CREATED_DATE'                  : 'PROPERTY_CREATEDATE',
            'PIPELINE_ID'                   : 'PROPERTY_HS_PIPELINE',
            'PIPELINE_STAGE_ID'             : 'PROPERTY_HS_PIPELINE_STAGE',
            'OBJECT_SOURCE'                 : 'PROPERTY_HS_OBJECT_SOURCE',
            'PROPERTY_HS_LASTMODIFIEDDATE'  : 'PROPERTY_HS_LASTMODIFIEDDATE'
    },
    'amh': {
            'TICKET_ID'                     : 'ID',
            'PROPERTY_HS_TICKET_ID'         : 'PROPERTY_HS_TICKET_ID',
            'CREATED_DATE'                  : 'PROPERTY_CREATEDATE',
            'PIPELINE_ID'                   : 'PROPERTY_HS_PIPELINE',
            'PIPELINE_STAGE_ID'             : 'PROPERTY_HS_PIPELINE_STAGE',
            'OBJECT_SOURCE'                 : 'PROPERTY_HS_OBJECT_SOURCE',
            'PROPERTY_HS_LASTMODIFIEDDATE'  : 'PROPERTY_HS_LASTMODIFIEDDATE'

    },
    'playfly': {
            'TICKET_ID'                     : 'ID',
            'PROPERTY_HS_TICKET_ID'         : 'PROPERTY_HS_TICKET_ID',
            'CREATED_DATE'                  : 'PROPERTY_CREATEDATE',
            'PIPELINE_ID'                   : 'PROPERTY_HS_PIPELINE',
            'PIPELINE_STAGE_ID'             : 'PROPERTY_HS_PIPELINE_STAGE',
            'OBJECT_SOURCE'                 : 'PROPERTY_HS_OBJECT_SOURCE',
            'PROPERTY_HS_LASTMODIFIEDDATE'  : 'PROPERTY_HS_LASTMODIFIEDDATE'

    }
  },

  'hubspot_pawville': {
    'wagway': {
            'TICKET_ID'                     : 'ID',
            'PROPERTY_HS_TICKET_ID'         : 'PROPERTY_HS_TICKET_ID',
            'CREATED_DATE'                  : 'PROPERTY_CREATEDATE',
            'PIPELINE_ID'                   : 'PROPERTY_HS_PIPELINE',
            'PIPELINE_STAGE_ID'             : 'PROPERTY_HS_PIPELINE_STAGE',
            'OBJECT_SOURCE'                 : 'PROPERTY_HS_OBJECT_SOURCE',
            'PROPERTY_HS_LASTMODIFIEDDATE'  : 'PROPERTY_HS_LASTMODIFIEDDATE'

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
