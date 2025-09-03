/*
{% macro get_target_database1(company) -%}
  {# company expected like 'wagway' or 'playfly' (case-insensitive) #}
  {% set company_up = company | upper %}
  {% set env_key = company_up ~ '_' ~ (target.name | upper) %}

  {# env_var will look for an environment variable named e.g. ZEROCHAOS_DEV or PEM_PROD #}
  {{ env_var(env_key, default=company_up ~ '_' ~ (target.name | lower)) }}
{%- endmacro %}
*/

{% macro get_target_database(company) -%}
  {# company is expected like 'zerochaos' or 'pem' #}
  {% set company_up = company | upper %}

  {# Build the env var name like DBT_ZEROCHAOS or DBT_PEM #}
  {% set env_key = 'DBT_' ~ company_up %}

  {# Read from environment variable, fallback to company_dev if not set #}
  {{ env_var(env_key, company | lower ~ '_dev1') }}
{%- endmacro %}

