{% set company = var("company", "wagway") %}
{{
    config(
        enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"]
        and var("company", "none") in ["wagway", "playfly", "amh"]
    )
}}


{{
    config(
        database=get_target_database(company),
        alias="dim_opportunity",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID_DATE_KEY",
    )
}}

with
    deal_contacts as (
        select distinct deal_id, max(contact_id) as contact_id
        from {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }}
        where is_active = 1
        group by 1
    ),

    stage_dates as (

        select
            ds.deal_id,
            dps.label as stage_name,
            dsm.mapped_stage_name,
            cast(ds.date_entered as date) as date_entered

        {% if company == "wagway" %} from WAGWAY_RAW.HUBSPOT.DEAL_STAGE ds

        {% elif company == "playfly"%} from PLAYFLY_RAW.HUBSPOT.DEAL_STAGE ds

        {% else %} from AMH_RAW.HUBSPOT.DEAL_STAGE ds

        {% endif %}
        left join
            {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} dps
            on dps.stage_id = ds.value
        left join
            {{ ref("hubspot_dim_stage_mapping") }} dsm
            on dps.label = dsm.stage_name
            {% if company == "wagway" %} and source_schema = 'HUBSPOT_PUPS'

            {% else %} and source_schema = concat('HUBSPOT_', '{{company | upper}}')

            {% endif %}
    ),
    stage_dates_by_opp as (

        select
            deal_id,

            /* ---- Final standardized funnel dates ---- */
            min(
                case when lower(mapped_stage_name) = 'opportunity' then date_entered end
            ) as opportunity_date,

            min(
                case when lower(mapped_stage_name) = 'proposal requested' then date_entered end
            ) as proposal_requested_date,

            min(
                case when lower(mapped_stage_name) = 'proposal sent' then date_entered end
            ) as proposal_sent_date,

            min(
                case when lower(mapped_stage_name) = 'negotiation' then date_entered end
            ) as negotiation_date,

            min(
                case when lower(mapped_stage_name) = 'closed won' then date_entered end
            ) as closed_won_date,

            min(
                case when lower(mapped_stage_name) = 'closed lost' then date_entered end
            ) as closed_lost_date

        from stage_dates
        group by deal_id
    )

    {% if company == "wagway" %}
        ,
        deal_contacts_pawville as (
            select distinct deal_id, max(contact_id) as contact_id
            from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_CONTACT") }}
            where is_active = 1
            group by 1
        )

        ,stage_dates_pawville as (

            select
                ds.deal_id,
                dps.label as stage_name,
                dsm.mapped_stage_name,
                cast(ds.date_entered as date) as date_entered
            from wagway_raw.hubspot_pawville.deal_stage ds
            left join
                {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} dps
                on dps.stage_id = ds.value
            left join
                {{ ref("hubspot_dim_stage_mapping") }} dsm
                on dps.label = dsm.stage_name
                and source_schema = 'HUBSPOT_PAWVILLE'
        ),
        stage_dates_by_opp_pawville as (

            select
                deal_id,

                /* ---- Final standardized funnel dates ---- */
                min(
                case when lower(mapped_stage_name) = 'opportunity' then date_entered end
                ) as opportunity_date,

                min(
                    case when lower(mapped_stage_name) = 'proposal requested' then date_entered end
                ) as proposal_requested_date,

                min(
                    case when lower(mapped_stage_name) = 'proposal sent' then date_entered end
                ) as proposal_sent_date,

                min(
                    case when lower(mapped_stage_name) = 'negotiation' then date_entered end
                ) as negotiation_date,

                min(
                    case when lower(mapped_stage_name) = 'closed won' then date_entered end
                ) as closed_won_date,

                min(
                    case when lower(mapped_stage_name) = 'closed lost' then date_entered end
                ) as closed_lost_date

            from stage_dates_pawville
            group by deal_id
        )

    {% endif %}

select distinct
    a.deal_id as opportunity_id,
    a.property_dealname as opportunity_name,
    a.property_createdate as opportunity_date,
    md5(
        coalesce(nullif(a.property_hs_analytics_source, ''), '')
        || '|'
        || coalesce('HUBSPOT', '')
    ) as sales_channel_id,

    {% if company == "playfly" %}
        md5(
            coalesce(a.property_product_group, '') || '|' || coalesce('HUBSPOT', '')
        ) as product_category_id,

    {% elif company == "wagway" %}
        md5(
            coalesce(a.property_service_category, '') || '|' || coalesce('HUBSPOT', '')
        ) as product_category_id,

    {% else %}
        md5(
            coalesce(a.property_service_request, '') || '|' || coalesce('HUBSPOT', '')
        ) as product_category_id,

    {% endif %}

    md5(
        coalesce(nullif(c.property_city, ''), '')
        || '|'
        || coalesce(nullif(c.property_state, ''), '')
        || '|'
        || coalesce(nullif(c.property_country, ''), '')
        || '|'
        || coalesce('HUBSPOT', '')
    ) as location_id,
    a.property_closedate as close_date,
    cast(
        case
            when
                a.property_closedate < current_timestamp()::timestamp_ntz
                and a.property_hs_is_closed_won = true
            then 1
            else 0
        end as boolean
    ) as is_won,
    cast(
        case
            when a.property_closedate < current_timestamp()::timestamp_ntz then 1 else 0
        end as boolean
    ) as is_closed,
    case
        when is_won = 1
        then
            coalesce(
                so.proposal_requested_date,
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_won_date,
                close_date
            )
        else
            coalesce(
                so.proposal_requested_date,
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_lost_date,
                close_date
            )
    end as proposal_requested_date,
    case
        when is_won = 1
        then
            coalesce(
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_won_date,
                close_date
            )
        else
            coalesce(
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_lost_date,
                close_date
            )
    end as proposal_sent_date,
    case
        when is_won = 1
        then coalesce(so.negotiation_date, so.closed_won_date, close_date)
        else coalesce(so.negotiation_date, so.closed_lost_date, close_date)
    end as negotiation_date,

    case
        when is_won = 1 then coalesce(so.closed_won_date, close_date) else null
    end as closed_won_date,
    case
        when is_won = 0 then coalesce(so.closed_lost_date, close_date) else null
    end as closed_lost_date,

    a.property_hs_lastmodifieddate as last_modified_date,

    {% if company == "wagway" %} 'HUBSPOT_PUPS' as source_schema,

    {% else %} concat('HUBSPOT_', '{{company | upper}}') as source_schema,

    {% endif %}

    current_timestamp()::timestamp_ntz as gold_load_date
from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
left join deal_contacts b on a.deal_id = b.deal_id
left join
    {{ get_silver_source(company, "HUBSPOT_CONTACT") }} c
    on c.id = b.contact_id
    and c.is_active = 1
left join stage_dates_by_opp so on so.deal_id = a.deal_id
where a.is_active = 1

{% if company == "wagway" %}

    union all

    select distinct
        a.deal_id as opportunity_id,
        a.property_dealname as opportunity_name,
        a.property_createdate as opportunity_date,
        md5(
            coalesce(nullif(a.property_hs_analytics_source, ''), '')
            || '|'
            || coalesce('HUBSPOT_PAWVILLE', '')
        ) as sales_channel_id,
        md5(
            coalesce(a.property_service_category, '')
            || '|'
            || coalesce('HUBSPOT_PAWVILLE', '')
        ) as product_category_id,
        md5(
            coalesce(nullif(c.property_city, ''), '')
            || '|'
            || coalesce(nullif(c.property_state, ''), '')
            || '|'
            || coalesce(nullif(c.property_country, ''), '')
            || '|'
            || coalesce('HUBSPOT_PAWVILLE', '')
        ) as location_id,
        a.property_closedate as close_date,
        cast(
            case
                when
                    a.property_closedate < current_timestamp()::timestamp_ntz
                    and a.property_hs_is_closed_won = true
                then 1
                else 0
            end as boolean
        ) as is_won,
        cast(
            case
                when a.property_closedate < current_timestamp()::timestamp_ntz
                then 1
                else 0
            end as boolean
        ) as is_closed,

        case
            when is_won = 1
            then
                coalesce(
                    so.proposal_requested_date,
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_won_date,
                    close_date
                )
            else
                coalesce(
                    so.proposal_requested_date,
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_lost_date,
                    close_date
                )
        end as proposal_requested_date,
        case
            when is_won = 1
            then
                coalesce(
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_won_date,
                    close_date
                )
            else
                coalesce(
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_lost_date,
                    close_date
                )
        end as proposal_sent_date,
        case
            when is_won = 1
            then coalesce(so.negotiation_date, so.closed_won_date, close_date)
            else coalesce(so.negotiation_date, so.closed_lost_date, close_date)
        end as negotiation_date,

        case
            when is_won = 1 then coalesce(so.closed_won_date, close_date) else null
        end as closed_won_date,
        case
            when is_won = 0 then coalesce(so.closed_lost_date, close_date) else null
        end as closed_lost_date,

        a.property_hs_lastmodifieddate as last_modified_date,
        'HUBSPOT_PAWVILLE' as source_schema,
        current_timestamp()::timestamp_ntz as gold_load_date
    from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
    left join deal_contacts_pawville b on a.deal_id = b.deal_id
    left join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} c
        on c.id = b.contact_id
        and c.is_active = 1
    left join stage_dates_by_opp_pawville so on so.deal_id = a.deal_id
    where a.is_active = 1

{% endif %}