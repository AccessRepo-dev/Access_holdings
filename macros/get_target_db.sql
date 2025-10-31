{% macro get_target_database(company) -%}
  {% set company_up = company | upper %}
  {% set env_key = 'DBT_' ~ company_up %}
  {{ env_var(env_key, company | lower ~ '_dev') }}
{%- endmacro %}
