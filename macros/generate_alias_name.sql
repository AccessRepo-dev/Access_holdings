/*
{% macro generate_alias_name1(custom_alias_name=none, node=none) -%}
  {% set parent_folder = node.path.split('/')[-2] %}
  {% if custom_alias_name is not none %}
    {{ parent_folder }}_{{ custom_alias_name }}
  {% else %}
    {{ parent_folder }}_{{ node.name }}
  {% endif %}
{%- endmacro %}
*/
{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
  {% if custom_alias_name is not none %}
    {{ custom_alias_name }}
  {% else %}
    {{ node.name }}
  {% endif %}
{%- endmacro %}
