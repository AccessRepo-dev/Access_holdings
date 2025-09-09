{% macro run_dynamic_models(company_name=None, source_system=None) %}
    {# --------------------------------------------
       Configure systems here based on your project
       (dbt_project.yml structure)
    --------------------------------------------- #}
    {% set silver_systems = ["netsuite", "sage"] %}
    {% set gold_systems = ["netsuite"] %}

    {% set selectors = [] %}

    {{ log("DEBUG → Args: company_name=" ~ (company_name or "None") ~ 
           ", source_system=" ~ (source_system or "None"), info=True) }}

    {# --------------------------
       Build selectors for SILVER
    --------------------------- #}
    {% for sys in silver_systems %}
        {% if (not source_system or source_system == sys) %}
            {% if company_name %}
                {% do selectors.append("path:models/integrations/silver/" ~ sys ~ " vars:{company_name: " ~ company_name ~ "}") %}
            {% else %}
                {% do selectors.append("path:models/integrations/silver/" ~ sys) %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {# --------------------------
       Build selectors for GOLD
    --------------------------- #}
    {% for sys in gold_systems %}
        {% if (not source_system or source_system == sys) %}
            {% if company_name %}
                {% do selectors.append("path:models/integrations/gold/" ~ sys ~ " vars:{company_name: " ~ company_name ~ "}") %}
            {% else %}
                {% do selectors.append("path:models/integrations/gold/" ~ sys) %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {# --------------------------
       Log and Return
    --------------------------- #}
    {{ log("==== Final Selector List ====", info=True) }}
    {% for sel in selectors %}
        {{ log(sel, info=True) }}
    {% endfor %}

    {% if selectors | length == 0 %}
        {{ log("⚠️ No matching selectors found!", info=True) }}
    {% endif %}

    {{ return(selectors) }}
{% endmacro %}
