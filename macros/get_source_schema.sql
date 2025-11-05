{% macro source_snapshot_schema(sourcesystem) -%}
  {% set sourcesystem = sourcesystem | lower %}
  {% set schema_name = sourcesystem | lower ~ '_snapshots' %}
  {{ return(schema_name) }}
{%- endmacro %}