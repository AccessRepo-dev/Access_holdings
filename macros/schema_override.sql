/*{% macro generate_schema_name1(custom_schema_name, node) -%}
 
    {%- set default_schema = target.schema -%}
    {%- set dbt_env = env_var("DBT_CLOUD_ENVIRONMENT_NAME") -%}
 
    {%- if dbt_env == "Development" -%} {{ default_schema | trim }}
    {%- elif custom_schema_name is none -%} {{ default_schema | trim }}
    {%- elif custom_schema_name is not none -%} {{ custom_schema_name | trim }}
    {%- else -%} {{ default_schema | trim }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}

{% macro generate_schema_name2(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}  {# schema from project.yml #}
    {%- set dbt_env = env_var("DBT_CLOUD_ENVIRONMENT_NAME", "Unknown") -%}

    {# Case 1: Development or Production → use schema from project.yml #}
    {%- if dbt_env in ["Development"] -%}
        {{ default_schema | trim }}_{{ custom_schema_name | trim }}

    {# Case 2: All other environments → custom_schema + default_schema #}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
*/
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- set dbt_env = env_var("DBT_ENVIRONMENT_NAME", "Unknown") -%}
    {%- set deploy_shared = var("deploy_to_shared_silver", false) -%}
    {%- set is_ci = var("is_ci_run", false) -%}

    {%- if is_ci -%}
        {{ default_schema | trim }}

    {%- elif dbt_env in ["Production", "Staging"] -%}
        {{ custom_schema_name | trim }}

    {%- elif dbt_env == "Development" and deploy_shared -%}
        {{ custom_schema_name | trim }}

    {%- elif dbt_env == "Development" -%}
        {{ default_schema | trim }}_{{ custom_schema_name | trim }}

    {%- else -%}
        {{ default_schema | trim }}
    {%- endif -%}
{%- endmacro %}