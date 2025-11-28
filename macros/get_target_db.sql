{% macro get_target_database(company) -%}
  {% set company_up = company | upper %}
  {% set env_key = 'DBT_' ~ company_up %}
  {{ env_var(env_key, company | lower ~ '_dev') }}
{%- endmacro %}


{% macro get_raw_database(company) -%}
  {% set company_up = company | upper %}
  {% set raw_company = company_up ~ '_raw' %}
  {{return(raw_company)}}
{%- endmacro %}