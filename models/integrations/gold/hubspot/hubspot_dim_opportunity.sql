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
            a.property_dealname as opportunity_name,
            c.id as contact_id,
            case
                when a.property_createdate > a.property_closedate
                then a.property_closedate
                else a.property_createdate
            end as property_createdate_new,
            case
                when (property_invoice_id is not null or b.label ilike '%purchase%')
                then property_createdate_new
            end as purchase_date,
            a.property_closedate as close_date,
            a.property_hs_lastmodifieddate,
            a.property_hs_analytics_source,
            a.deal_pipeline_id,
            a.property_invoice_id,
            b.label as stage_name,
            {% if company == "wagway" %} a.PROPERTY_CLUB_C as hub,
            {% elif company == "amh" %} a.property_property_source as hub,
            {% else %} 'Unknown' as hub,
            {% endif %}
            a.property_hs_is_closed_lost,

            /* ---- calculated once ---- */
            cast(
                case
                    when stage_name ilike 'close%' and stage_name ilike '%won'
                    then 1
                    else 0
                end as boolean
            ) as is_won,
            cast(
                case when stage_name ilike 'close%' then 1 else 0 end as boolean
            ) as is_closed,
            md5(
                coalesce(nullif(a.property_hs_analytics_source, ''), '') || '|HUBSPOT'
            ) as sales_channel_id,


            {% if company == "wagway" %}
                array_compact(
                    array_construct(
                        case when opportunity_name ilike '%Daycare%' then 'Daycare' end,
                        case
                            when
                                opportunity_name ilike '%Grooming%'
                                or opportunity_name ilike '%Groom%'
                            then 'Grooming'
                        end,
                        case when opportunity_name ilike '%Training%' then 'Training' end,
                        case
                            when
                                opportunity_name ilike '%Pet Sitting%'
                                or opportunity_name ilike '%Petsitting%'
                                or opportunity_name ilike '%Pet-Sitting%'
                            then 'Pet Sitting'
                        end,
                        case
                            when
                                opportunity_name ilike '%Overnights%'
                                or opportunity_name ilike '%Overnight%'
                            then 'Overnights'
                        end,
                        case when opportunity_name ilike '%Boarding%' then 'Boarding' end,
                        case when opportunity_name ilike '%Walking%' then 'Walking' end,
                        case
                            when
                                opportunity_name ilike '%Puppy Play Care%'
                                or opportunity_name ilike '%Puppy Playcare%'
                            then 'Puppy Playcare'
                        end,
                        case when opportunity_name ilike '%Playcare%' then 'Playcare' end,
                        case when opportunity_name ilike '%Gingr Sign Up%' then 'Gingr Sign Up' end,
                        case when opportunity_name ilike '%New Lead%' then 'New Lead' end,
                        case when opportunity_name ilike '%Membership%' then 'Membership' end,
                        case
                            when
                                opportunity_name ilike '%Wellness%'
                                or opportunity_name ilike '%WellCare%'
                                or opportunity_name ilike '%Well Care%'
                            then 'Wellness'
                        end,
                        case when opportunity_name ilike '%Transport%' then 'Transport' end,
                        case
                            when
                                opportunity_name ilike '%Veterinary%'
                                or opportunity_name ilike '%Vet%'
                            then 'Veterinary'
                        end,
                        case when opportunity_name ilike '%General%' then 'General' end
                    )
                ) as svc_array,
                case
                    when array_size(svc_array) = 0
                    then md5(
                                '' || '|HUBSPOT'
                            )
                    when
                        lower(svc_array[0]::string) in ('new lead', 'gingr sign up')
                        and array_size(svc_array) > 1
                    then md5(
                                coalesce(svc_array[1]::string, '') || '|HUBSPOT'
                            )
                    else md5(
                                coalesce(svc_array[0]::string, '') || '|HUBSPOT'
                            ) end 
            {%elif company == "playfly" %}
                md5(coalesce(nullif(a.property_product_group, ''), '') || '|HUBSPOT')
            {% else %}
                md5(coalesce(nullif(a.property_service_request, ''), '') || '|HUBSPOT')
            {% endif %} as product_category_id,

            md5(
                coalesce(nullif(c.property_city, ''), '')
                || '|'
                || coalesce(nullif(c.property_state, ''), '')
                || '|'
                || coalesce(nullif(c.property_country, ''), '')
                || '|HUBSPOT'
            ) as location_id
        from {{ get_silver_source(company, "HUBSPOT_DEAL") }} a
        left join deal_contacts dc on a.deal_id = dc.deal_id
        left join
            {{ get_silver_source(company, "HUBSPOT_CONTACT") }} c
            on c.id = dc.contact_id
            and c.is_active = 1
        left join
            {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE_STAGE") }} b
            on b.stage_id = a.deal_pipeline_stage_id
            and b.is_active = 1
            where a.is_active = 1
    )

    {% if company == "wagway" %}
        ,base_deals_pawville as (
            select
                a.deal_id,
                a.property_dealname as opportunity_name,
                c.id as contact_id,
                case
                    when a.property_createdate > a.property_closedate
                    then a.property_closedate
                    else a.property_createdate
                end as property_createdate_new,
                case
                    when (property_invoice_id is not null or b.label ilike '%purchase%')
                    then property_createdate_new
                end as purchase_date,
                a.property_closedate as close_date,
                a.property_hs_lastmodifieddate,
                a.property_hs_analytics_source,
                a.deal_pipeline_id,
                a.property_invoice_id,
                b.label as stage_name,
                'Unknown' as hub,
                a.property_hs_is_closed_lost,

                cast(
                    case
                        when stage_name ilike 'close%' and stage_name ilike '%won'
                        then 1
                        else 0
                    end as boolean
                ) as is_won,
                cast(
                    case when stage_name ilike 'close%' then 1 else 0 end as boolean
                ) as is_closed,
                md5(
                    coalesce(nullif(a.property_hs_analytics_source, ''), '')
                    || '|HUBSPOT_PAWVILLE'
                ) as sales_channel_id,
                
                {% if company == "wagway" %}
                array_compact(
                    array_construct(
                        case when opportunity_name ilike '%Daycare%' then 'Daycare' end,
                        case
                            when
                                opportunity_name ilike '%Grooming%'
                                or opportunity_name ilike '%Groom%'
                            then 'Grooming'
                        end,
                        case when opportunity_name ilike '%Training%' then 'Training' end,
                        case
                            when
                                opportunity_name ilike '%Pet Sitting%'
                                or opportunity_name ilike '%Petsitting%'
                                or opportunity_name ilike '%Pet-Sitting%'
                            then 'Pet Sitting'
                        end,
                        case
                            when
                                opportunity_name ilike '%Overnights%'
                                or opportunity_name ilike '%Overnight%'
                            then 'Overnights'
                        end,
                        case when opportunity_name ilike '%Boarding%' then 'Boarding' end,
                        case when opportunity_name ilike '%Walking%' then 'Walking' end,
                        case
                            when
                                opportunity_name ilike '%Puppy Play Care%'
                                or opportunity_name ilike '%Puppy Playcare%'
                            then 'Puppy Playcare'
                        end,
                        case when opportunity_name ilike '%Playcare%' then 'Playcare' end,
                        case when opportunity_name ilike '%Gingr Sign Up%' then 'Gingr Sign Up' end,
                        case when opportunity_name ilike '%New Lead%' then 'New Lead' end,
                        case when opportunity_name ilike '%Membership%' then 'Membership' end,
                        case
                            when
                                opportunity_name ilike '%Wellness%'
                                or opportunity_name ilike '%WellCare%'
                                or opportunity_name ilike '%Well Care%'
                            then 'Wellness'
                        end,
                        case when opportunity_name ilike '%Transport%' then 'Transport' end,
                        case
                            when
                                opportunity_name ilike '%Veterinary%'
                                or opportunity_name ilike '%Vet%'
                            then 'Veterinary'
                        end,
                        case when opportunity_name ilike '%General%' then 'General' end
                    )
                ) as svc_array,
                case
                    when array_size(svc_array) = 0
                    then md5(
                                '' || '|HUBSPOT_PAWVILLE'
                            )
                    when
                        lower(svc_array[0]::string) in ('new lead', 'gingr sign up')
                        and array_size(svc_array) > 1
                    then md5(
                                coalesce(svc_array[1]::string, '') || '|HUBSPOT_PAWVILLE'
                            )
                    else md5(
                                coalesce(svc_array[0]::string, '') || '|HUBSPOT_PAWVILLE'
                            )
                end as product_category_id,
            {%else%}
                md5(
                    coalesce(a.property_service_category, '') || '|HUBSPOT_PAWVILLE'
                ) as product_category_id,
            {% endif %}

                md5(
                    coalesce(nullif(c.property_city, ''), '')
                    || '|'
                    || coalesce(nullif(c.property_state, ''), '')
                    || '|'
                    || coalesce(nullif(c.property_country, ''), '')
                    || '|HUBSPOT_PAWVILLE'
                ) as location_id
            from {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL") }} a
            left join
                {{ get_silver_source(company, "HUBSPOT_PAWVILLE_DEAL_PIPELINE_STAGE") }} b
                on b.stage_id = a.deal_pipeline_stage_id
                and b.is_active = 1
            left join deal_contacts dc on dc.deal_id = a.deal_id
            left join
                {{ get_silver_source(company, "HUBSPOT_CONTACT") }} c
                on c.id = dc.contact_id
                and c.is_active = 1
            where a.is_active = 1
        )
    {% endif %}
    /* =======================================================
   FINAL SELECT
======================================================= */
    ,final as (
        select
            bd.deal_id as opportunity_id,
            bd.opportunity_name,
            bd.property_createdate_new as opportunity_date,
            contact_id,
            case
                when bd.contact_id is null
                then null
                else min(purchase_date) over (partition by contact_id)
            end as acquisition_date,
            bd.stage_name,
            bd.hub,
            bd.sales_channel_id,
            bd.product_category_id,
            bd.location_id,
            bd.close_date,
            bd.is_closed,
            bd.is_won,
            min(bd.property_createdate_new) over (partition by contact_id) as contact_date,

            case
                when bd.is_won = 1
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
                when bd.is_won = 1
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
                when bd.is_won = 1
                then coalesce(so.negotiation_date, so.closed_won_date, bd.close_date)
                else coalesce(so.negotiation_date, so.closed_lost_date, bd.close_date)
            end as negotiation_date,

            case
                when bd.is_won = 1 then coalesce(so.closed_won_date, bd.close_date)
            end as closed_won_date,
            case
                when bd.is_won <> 1 then coalesce(so.closed_lost_date, bd.close_date)
            end as closed_lost_date,

            dp.label as pipeline_name,
            property_hs_is_closed_lost
        from base_deals bd
        left join stage_dates_by_opp so on so.deal_id = bd.deal_id
        left join
            {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE") }} dp
            on dp.pipeline_id = bd.deal_pipeline_id
            and dp.is_active = 1

        {% if company == "wagway" %}

            union all

            select
                bd.deal_id as opportunity_id,
                bd.opportunity_name,
                bd.property_createdate_new as opportunity_date,
                contact_id,
                case
                    when bd.contact_id is null
                    then null
                    else min(purchase_date) over (partition by contact_id)
                end as acquisition_date,
                bd.stage_name,
                bd.hub,
                bd.sales_channel_id,
                bd.product_category_id,
                bd.location_id,
                bd.close_date,
                bd.is_closed,
                bd.is_won,
                min(bd.property_createdate_new) over (
                    partition by contact_id
                ) as contact_date,

                case
                when bd.is_won = 1
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
                when bd.is_won = 1
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
                when bd.is_won = 1
                then coalesce(so.negotiation_date, so.closed_won_date, bd.close_date)
                else coalesce(so.negotiation_date, so.closed_lost_date, bd.close_date)
            end as negotiation_date,

            case
                when bd.is_won = 1 then coalesce(so.closed_won_date, bd.close_date)
            end as closed_won_date,
            case
                when bd.is_won <> 1 then coalesce(so.closed_lost_date, bd.close_date)
            end as closed_lost_date,

            dp.label as pipeline_name,
            property_hs_is_closed_lost

            from base_deals_pawville bd
            left join stage_dates_by_opp_pawville so on so.deal_id = bd.deal_id
            left join
                {{ get_silver_source(company, "HUBSPOT_DEAL_PIPELINE") }} dp
                on dp.pipeline_id = bd.deal_pipeline_id
                and dp.is_active = 1

        {% endif %}
    )

select
            distinct
            opportunity_id,
            opportunity_name,
            opportunity_date,
            acquisition_date, 
            hub, 
            sales_channel_id,
            product_category_id,
            location_id,
            contact_id,
            close_date,
            is_closed,
            is_won,
            contact_date,
            proposal_requested_date,
            proposal_sent_date,
            negotiation_date,
            closed_won_date,
            closed_lost_date,
            {% if company == "wagway" %}
            case
                when acquisition_date is not null
                then 'Closed Won'
                when
                    sum(
                        case
                            when
                                property_hs_is_closed_lost = false
                                and acquisition_date is null
                            then 1
                            else 0
                        end
                    ) over (partition by contact_id)
                    > 0
                then 'Open Lead'
                else 'Closed Lost'
            end as lead_status,
            {% elif company == "amh" %}
            case 
                when stage_name ilike 'closed%' and stage_name ilike '%won' 
                then 'Closed Won'
                when stage_name ilike 'closed%' and stage_name ilike '%lost' 
                then 'Closed Lost'
                else 'Open Lead' end as lead_status,
            {%else %} null as lead_status,
            {% endif %} 
            pipeline_name,
            -- last_modified_date,
            current_timestamp()::timestamp_ntz as gold_load_date
    
from final