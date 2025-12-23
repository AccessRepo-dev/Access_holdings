{% set company = var("company", "wagway") %}

{{
    config(
        enabled=var("sourcesystem", "none") in ["hubspot", "hubspot_pawville"]
        and company in ["wagway", "playfly", "amh"]
    )
}}

{{
    config(
        database=get_target_database(company),
        alias="dim_opportunity",
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="OPPORTUNITY_ID",
    )
}}

with
    /* =======================================================
   CONTACTS
======================================================= */
    deal_contacts as (
        select deal_id, max(contact_id) as contact_id
        from {{ get_silver_source(company, "HUBSPOT_DEAL_CONTACT") }}
        where is_active = 1
        group by deal_id
    ),

    {% if company == "wagway" %}
        deal_contacts_pawville as (
            select deal_id, max(contact_id) as contact_id
            from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_CONTACT") }}
            where is_active = 1
            group by deal_id
        ),
    {% endif %}

    /* =======================================================
   STAGE HISTORY
======================================================= */
    stage_dates as (
        select
            ds.deal_id,
            dsm.mapped_stage_name,
            cast(ds.date_entered as date) as date_entered
        {% if company == "wagway" %} from wagway_raw.hubspot.deal_stage ds
        {% elif company == "playfly" %} from playfly_raw.hubspot.deal_stage ds
        {% else %} from amh_raw.hubspot.deal_stage ds
        {% endif %}
        left join
            {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} dps
            on dps.stage_id = ds.value
        left join
            {{ ref("hubspot_dim_stage_mapping") }} dsm on dps.label = dsm.stage_name
            {% if company == "wagway" %} and source_schema = 'HUBSPOT_PUPS'
            {% else %} and source_schema = concat('HUBSPOT_', '{{ company | upper }}')
            {% endif %}
    ),

    stage_dates_by_opp as (
        select
            deal_id,
            min(
                case when lower(mapped_stage_name) = 'opportunity' then date_entered end
            ) as opportunity_date,
            min(
                case
                    when lower(mapped_stage_name) = 'proposal requested'
                    then date_entered
                end
            ) as proposal_requested_date,
            min(
                case
                    when lower(mapped_stage_name) = 'proposal sent' then date_entered
                end
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
    ),

    {% if company == "wagway" %}
        stage_dates_pawville as (
            select
                ds.deal_id,
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
                min(
                    case
                        when lower(mapped_stage_name) = 'opportunity' then date_entered
                    end
                ) as opportunity_date,
                min(
                    case
                        when lower(mapped_stage_name) = 'proposal requested'
                        then date_entered
                    end
                ) as proposal_requested_date,
                min(
                    case
                        when lower(mapped_stage_name) = 'proposal sent'
                        then date_entered
                    end
                ) as proposal_sent_date,
                min(
                    case
                        when lower(mapped_stage_name) = 'negotiation' then date_entered
                    end
                ) as negotiation_date,
                min(
                    case
                        when lower(mapped_stage_name) = 'closed won' then date_entered
                    end
                ) as closed_won_date,
                min(
                    case
                        when lower(mapped_stage_name) = 'closed lost' then date_entered
                    end
                ) as closed_lost_date
            from stage_dates_pawville
            group by deal_id
        ),
    {% endif %}

    /* =======================================================
   BASE DEALS (CALCULATED FIELDS LIVE HERE)
======================================================= */
    base_deals as (
        select
            a.deal_id,
            a.property_dealname,
            a.property_createdate,
            a.property_closedate as close_date,
            a.property_hs_lastmodifieddate,
            a.property_hs_analytics_source,
            a.deal_pipeline_id,

            /* ---- calculated once ---- */
            case when a.stage_name ilike 'close%' and a.stage_name ilike '%won' then 1 else 0 end as IS_WON,
            case when a.stage_name ilike 'close%' then 1 else 0 end as IS_CLOSED
            -- ,

            -- cast(
            --     a.property_closedate < current_timestamp()::timestamp_ntz as boolean
            -- ) as is_closed,

            -- cast(
            --     a.property_closedate < current_timestamp()::timestamp_ntz
            --     and a.property_hs_is_closed_won = true as boolean
            -- ) as is_won

        from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
        where a.is_active = 1
    ),

    {% if company == "wagway" %}
        base_deals_pawville as (
            select
                a.deal_id,
                a.property_dealname,
                a.property_createdate,
                a.property_closedate as close_date,
                a.property_hs_lastmodifieddate,
                a.property_hs_analytics_source,
                a.deal_pipeline_id,

                case when a.stage_name ilike 'close%' and a.stage_name ilike '%won' then 1 else 0 end as IS_WON,
                case when a.stage_name ilike 'close%' then 1 else 0 end as IS_CLOSED,

                -- cast(
                --     a.property_closedate < current_timestamp()::timestamp_ntz as boolean
                -- ) as is_closed,

                -- cast(
                --     a.property_closedate < current_timestamp()::timestamp_ntz
                --     and a.property_hs_is_closed_won = true as boolean
                -- ) as is_won

            from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
            where a.is_active = 1
        )
    {% endif %}

/* =======================================================
   FINAL SELECT
======================================================= */
select
    bd.deal_id as opportunity_id,
    bd.property_dealname as opportunity_name,
    bd.property_createdate as opportunity_date,
    bd.close_date,
    bd.is_closed,
    bd.is_won,

    case
        when bd.is_won
        then
            coalesce(
                so.proposal_requested_date,
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_won_date,
                bd.close_date
            )
        else
            coalesce(
                so.proposal_requested_date,
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_lost_date,
                bd.close_date
            )
    end as proposal_requested_date,

    case
        when bd.is_won
        then
            coalesce(
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_won_date,
                bd.close_date
            )
        else
            coalesce(
                so.proposal_sent_date,
                so.negotiation_date,
                so.closed_lost_date,
                bd.close_date
            )
    end as proposal_sent_date,

    case
        when bd.is_won
        then coalesce(so.negotiation_date, so.closed_won_date, bd.close_date)
        else coalesce(so.negotiation_date, so.closed_lost_date, bd.close_date)
    end as negotiation_date,

    case
        when bd.is_won then coalesce(so.closed_won_date, bd.close_date)
    end as closed_won_date,
    case
        when not bd.is_won then coalesce(so.closed_lost_date, bd.close_date)
    end as closed_lost_date,

    dp.label as pipeline_name,
    bd.property_hs_lastmodifieddate as last_modified_date,
    current_timestamp()::timestamp_ntz as gold_load_date

from base_deals bd
left join deal_contacts dc on dc.deal_id = bd.deal_id
left join
    {{ get_silver_source(company, "HUBSPOT_CONTACT") }} c
    on c.id = dc.contact_id
    and c.is_active = 1
left join stage_dates_by_opp so on so.deal_id = bd.deal_id
left join
    {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE") }} dp
    on dp.pipeline_id = bd.deal_pipeline_id
    and dp.is_active = 1

{% if company == "wagway" %}

    union all

    select
        bd.deal_id as opportunity_id,
        bd.property_dealname as opportunity_name,
        bd.property_createdate as opportunity_date,
        bd.close_date,
        bd.is_closed,
        bd.is_won,

        case
            when bd.is_won
            then
                coalesce(
                    so.proposal_requested_date,
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_won_date,
                    bd.close_date
                )
            else
                coalesce(
                    so.proposal_requested_date,
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_lost_date,
                    bd.close_date
                )
        end,

        case
            when bd.is_won
            then
                coalesce(
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_won_date,
                    bd.close_date
                )
            else
                coalesce(
                    so.proposal_sent_date,
                    so.negotiation_date,
                    so.closed_lost_date,
                    bd.close_date
                )
        end,

        case
            when bd.is_won
            then coalesce(so.negotiation_date, so.closed_won_date, bd.close_date)
            else coalesce(so.negotiation_date, so.closed_lost_date, bd.close_date)
        end,

        case when bd.is_won then coalesce(so.closed_won_date, bd.close_date) end,
        case when not bd.is_won then coalesce(so.closed_lost_date, bd.close_date) end,

        dp.label,
        bd.property_hs_lastmodifieddate,
        current_timestamp()::timestamp_ntz

    from base_deals_pawville bd
    left join deal_contacts_pawville dc on dc.deal_id = bd.deal_id
    left join
        {{ get_silver_source(company, "HUBSPOT_PAWVILLE_CONTACT") }} c
        on c.id = dc.contact_id
        and c.is_active = 1
    left join stage_dates_by_opp_pawville so on so.deal_id = bd.deal_id
    left join
        {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE") }} dp
        on dp.pipeline_id = bd.deal_pipeline_id
        and dp.is_active = 1

{% endif %}