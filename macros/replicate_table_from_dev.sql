{% macro replicate_table_from_dev(source_database, source_schema, table_name) %}
    {%- set current_database = source_database -%}
    {%- set is_ci = var("is_ci_run", false) -%}
    {# In CI: use target.schema (default schema) #}
    {%- if is_ci -%}
        {%- set current_schema = target.schema -%}
        {{ log("CI Job: Using target schema: " ~ current_schema, info=True) }}

    {# In CD: use schema from config (dbt_project.yml) #}
    {%- else -%}
        {%- set current_schema = this.schema -%}
        {{ log("CD Job: Using configured schema: " ~ current_schema, info=True) }}
    {%- endif -%}
    {%- set dbt_env = env_var("DBT_ENVIRONMENT_NAME", "Production") -%}

    {# Only run this in non-production environments #}
    {% if dbt_env != "Production" %}

        {# Check if table exists in current environment #}
        {% set table_exists_query %}
            SELECT COUNT(*) AS table_count
            FROM {{ current_database }}.INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = UPPER('{{ current_schema }}')
              AND TABLE_NAME = UPPER('{{ table_name }}')
        {% endset %}

        {% set results = run_query(table_exists_query) %}

        {% if execute %}
            {% set table_count = results.columns[0].values()[0] %}

            {% if table_count == 0 %}
                {{
                    log(
                        "Table '"
                        ~ table_name
                        ~ "' does not exist in "
                        ~ current_schema
                        ~ " schema. Replicating from DEV environment...",
                        info=True,
                    )
                }}

                {# Create the table by cloning from production #}
                {% set clone_query %}
                    CREATE TABLE IF NOT EXISTS {{ current_database }}.{{ current_schema }}.{{ table_name }}
                    CLONE {{ source_database }}.{{ source_schema }}.{{ table_name }}
                {% endset %}

                {% do run_query(clone_query) %}

                {{
                    log(
                        "Successfully replicated '" ~ table_name ~ "' from DEV env!",
                        info=True,
                    )
                }}
            {% else %}
                {{
                    log(
                        "Table '"
                        ~ table_name
                        ~ "' already exists. Skipping replication.",
                        info=True,
                    )
                }}
            {% endif %}
        {% endif %}

    {% else %}
        {{
            log(
                "Running in environment. Skipping table replication check.", info=True
            )
        }}
    {% endif %}
{% endmacro %}
