{% set company = var('company', 'amh') | lower %}
{% set sourcesystem = var('sourcesystem','hubspot') | lower %}


{{
    config(
        enabled=(var("sourcesystem", "hubspot") | lower) in ["hubspot"]
        and (var("company", "amh") | lower) in ["wagway", "playfly", "amh"],
        database=get_target_database(company),
        alias="fact_opportunity",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with
    pups_hashed as (

        select
            a.deal_id as id,
            property_dealname,
            contact_id,
            case
                when contact_id is null
                then null
                else
                    min(
                        case
                            when
                                (
                                    property_invoice_id is not null
                                    or label ilike '%purchase%'
                                )
                            then least(property_closedate, property_createdate)
                        end
                    ) over (partition by contact_id)
            end as acquisition_date,
            property_hs_is_closed_lost,
            case
                when property_createdate > property_closedate
                then property_closedate
                else property_createdate
            end as property_createdate,
            min(property_createdate) over (partition by contact_id) as contact_date,
            b.label as stage_name,
            owner_id as owner_id,
            a.property_amount as amount,
            a.property_closedate as close_date,
            case
                when
                    dsm.mapped_stage_name ilike 'close%'
                    and dsm.mapped_stage_name ilike '%won'
                then 1
                else 0
            end as is_won_n,
            case
                when dsm.mapped_stage_name ilike 'close%' then 1 else 0
            end as is_closed_n,
            -- cast(CASE WHEN A.property_closedate <
            -- CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS
            -- IS_CLOSED,
            -- cast(CASE WHEN A.property_closedate <
            -- CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won =
            -- TRUE THEN 1
            -- ELSE 0 END as Boolean) as IS_WON,
            property_hs_deal_stage_probability as probability,
            a.dbt_valid_from,
            a.dbt_valid_to,
            md5(
                coalesce(stage_name, '')
                || '|'
                || coalesce(property_amount::string, '')
                || '|'
                || coalesce(owner_id::string, '')
                || '|'
                || coalesce(close_date::string, '')
                || '|'
                || coalesce(is_won_n::string, '')
                || '|'
                || coalesce(is_closed_n::string, '')
            ) as attr_hash,
            property_hs_projected_amount,
            {% if sourcesystem == "hubspot" %}
            company_id
            {% endif %}
        from {{ ref('hubspot_deal_current') }} a
        left join
            {{ ref('hubspot_deal_contact_current') }} c
            on a.deal_id = c.deal_id

        left join
            {{ ref('hubspot_deal_pipeline_stage_current') }} b
            on b.stage_id = a.deal_pipeline_stage_id
            and b.is_active = 1
        {% if sourcesystem == "hubspot" %}
        left join
            {{ ref('hubspot_deal_company_current') }} d
            on a.deal_id = d.deal_id
        {% endif %}

        left join
            {{ ref("hubspot_dim_stage_mapping") }} dsm on b.label = dsm.stage_name
            {% if company == "wagway" %} and dsm.source_schema = 'HUBSPOT_PUPS'
            {% else %}
                and dsm.source_schema = concat('HUBSPOT_', '{{ company | upper }}')
            {% endif %}

    )
    {% if company == "wagway" %}

        ,
        pawville_hashed as (

            select
                a.deal_id as id,
                property_dealname,
                contact_id,
                case
                    when contact_id is null
                    then null
                    else
                        min(
                            case
                                when
                                    (
                                        property_invoice_id is not null
                                        or label ilike '%purchase%'
                                    )
                                then least(property_closedate, property_createdate)
                            end
                        ) over (partition by contact_id)
                end as acquisition_date,
                property_hs_is_closed_lost,
                case
                    when property_createdate > property_closedate
                    then property_closedate
                    else property_createdate
                end as property_createdate,
                min(property_createdate) over (partition by contact_id) as contact_date,
                b.label as stage_name,
                owner_id as owner_id,
                a.property_amount as amount,
                a.property_closedate as close_date,
                case
                    when
                        dsmm.mapped_stage_name ilike 'close%'
                        and dsmm.mapped_stage_name ilike '%won'
                    then 1
                    else 0
                end as is_won_n,
                case
                    when dsmm.mapped_stage_name ilike 'close%' then 1 else 0
                end as is_closed_n,
                -- cast(CASE WHEN A.property_closedate <
                -- CURRENT_TIMESTAMP()::TIMESTAMP_NTZ THEN 1 ELSE 0 END as Boolean) AS
                -- IS_CLOSED,
                -- cast(CASE WHEN A.property_closedate <
                -- CURRENT_TIMESTAMP()::TIMESTAMP_NTZ and A.property_hs_is_closed_won
                -- = TRUE THEN 1
                -- ELSE 0 END as Boolean) as IS_WON,
                property_hs_deal_stage_probability as probability,
                a.dbt_valid_from,
                a.dbt_valid_to,
                md5(
                    coalesce(stage_name, '')
                    || '|'
                    || coalesce(property_amount::string, '')
                    || '|'
                    || coalesce(owner_id::string, '')
                    || '|'
                    || coalesce(close_date::string, '')
                    || '|'
                    || coalesce(is_won_n::string, '')
                    || '|'
                    || coalesce(is_closed_n::string, '')
                ) as attr_hash,
                property_hs_projected_amount,
                null as company_id,
            from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
            left join
                {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_CONTACT") }} c
                on a.deal_id = c.deal_id
            left join
                {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} b
                on b.stage_id = a.deal_pipeline_stage_id
                and b.is_active = 1
            left join
                {{ ref("hubspot_dim_stage_mapping") }} dsmm
                on b.label = dsmm.stage_name
                and dsmm.source_schema = 'HUBSPOT_PAWVILLE'

        )

    {% endif %},
    final as (
        select
            concat(
                id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
            ) as id_date_key,
            id as opportunity_id,
            md5(
                coalesce(nullif(cast(owner_id as string), ''), '') || '|' || 'HUBSPOT'
            ) as owner_id,
            stage_name,
            amount,
            close_date,
            cast(is_closed_n as boolean) as is_closed,
            cast(is_won_n as boolean) as is_won,
            probability * 100 as probability,
            min(dbt_valid_from) over (partition by id, attr_hash) as dbt_valid_from,
            case
                when
                    max(case when dbt_valid_to is null then 1 else 0 end) over (
                        partition by id, attr_hash
                    )
                    = 1
                then null
                else max(dbt_valid_to) over (partition by id, attr_hash)
            end as dbt_valid_to,
            max(case when dbt_valid_to is null then 1 else 0 end) over (
                partition by id, attr_hash
            ) as is_active,

            {% if company == "wagway" %}
                md5(coalesce(stage_name, '') || '|HUBSPOT_PUPS') as stage_key,
                'HUBSPOT_PUPS' as source_schema,

            {% else %}
                md5(
                    coalesce(stage_name, '')
                    || concat('HUBSPOT_', '{{company | upper}}')
                ) as stage_key,
                concat('HUBSPOT_', '{{company | upper}}') as source_schema,

            {% endif %}
            company_id as dim_company_id,
            property_hs_projected_amount,
            current_timestamp()::timestamp_ntz as gold_load_date
        from pups_hashed
        qualify
            row_number() over (partition by id, attr_hash order by dbt_valid_from) = 1

        {% if company == "wagway" %}
            union all

            select
                concat(
                    id, '_', to_varchar(dbt_valid_from, 'YYYYMMDDHH24MISSFF3')
                ) as id_date_key,
                id as opportunity_id,
                md5(
                    coalesce(nullif(cast(owner_id as string), ''), '')
                    || '|'
                    || 'HUBSPOT_PAWVILLE'
                ) as owner_id,
                stage_name,
                amount,
                close_date,
                cast(is_closed_n as boolean) as is_closed,
                cast(is_won_n as boolean) as is_won,
                probability * 100 as probability,

                min(dbt_valid_from) over (partition by id, attr_hash) as dbt_valid_from,
                case
                    when
                        max(case when dbt_valid_to is null then 1 else 0 end) over (
                            partition by id, attr_hash
                        )
                        = 1
                    then null
                    else max(dbt_valid_to) over (partition by id, attr_hash)
                end as dbt_valid_to,
                max(case when dbt_valid_to is null then 1 else 0 end) over (
                    partition by id, attr_hash
                ) as is_active,
                md5(coalesce(stage_name, '') || '|HUBSPOT_PAWVILLE') as stage_key,

                'HUBSPOT_PAWVILLE' as source_schema,
                company_id as dim_company_id,
                property_hs_projected_amount,
                current_timestamp()::timestamp_ntz as gold_load_date
            from pawville_hashed
            qualify
                row_number() over (partition by id, attr_hash order by dbt_valid_from)
                = 1

        {% endif %}

    ),
    base as (select * from final),
    services as (select * from base)
select
    *,
    row_number() over (
        partition by opportunity_id, source_schema order by dbt_valid_from
    ) as rank
from services
