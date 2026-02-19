{% set company = var("company", "zeus") %}
{% set sourcesystem = var("sourcesystem", "salesforce") %}


{{
    config(
        enabled=(var("sourcesystem", "salesforce") | lower) in ["salesforce"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="opportunity_id",
        alias="dim_opportunity",
    )
}}

with
    Last_Stage as (

        select 
            row_number() OVER (PARTITION BY opportunity_id ORDER BY CREATED_DATE DESC) as row_num,
            opportunity_id,
            old_value as native_stage_name,
            old.mapped_stage_name
        from  {{ ref('salesforce_opportunity_field_history_current') }} o
        left join {{ ref('salesforce_dim_stage_mapping') }} new on trim(o.new_value) = new.stage_name
        left join {{ ref('salesforce_dim_stage_mapping') }} old on trim(o.old_value) = old.stage_name
        WHERE field = 'StageName' AND new.mapped_stage_name = 'Closed Lost' AND is_deleted = false and is_active = 1
        QUALIFY row_num = 1

    ),
    hist_stage_dates as (

        select opportunity_id, 

        sn.mapped_stage_name as mapped_stage_name, 
        created_date
        from 
        {{ ref('salesforce_opportunity_field_history_current') }} o
        left join
            {{ ref('salesforce_dim_stage_mapping') }} sn on trim(o.new_value) = sn.stage_name
        where o.field = 'StageName'

    ),

    hist_stage_dates_by_opp as (

        select
            opportunity_id,
            min(
                case when lower(mapped_stage_name) = 'opportunity' then created_date end
            ) as opportunity_date,
            min(
                case
                    when lower(mapped_stage_name) = 'proposal requested'
                    then created_date
                end
            ) as proposal_requested_date,
            min(
                case
                    when lower(mapped_stage_name) = 'proposal sent' then created_date
                end
            ) as proposal_sent_date,
            min(
                case when lower(mapped_stage_name) = 'negotiation' then created_date end
            ) as negotiation_date,
            min(
                case when lower(mapped_stage_name) = 'closed won' then created_date end
            ) as closed_won_date,
            min(
                case when lower(mapped_stage_name) = 'closed lost' then created_date end
            ) as closed_lost_date
        from hist_stage_dates
        group by opportunity_id

    ),

    stage_dates as (

        select a.opportunity_id, b.mapped_stage_name, a.dbt_valid_from as created_date
        from {{ ref("salesforce_fact_opportunity") }} a
        left join
            {{ ref("salesforce_dim_stage_mapping") }} b on a.stage_name = b.stage_name

    ),

    stage_dates_by_opp as (

        select
            opportunity_id,
            min(
                case when lower(mapped_stage_name) = 'opportunity' then created_date end
            ) as opportunity_date,
            min(
                case
                    when lower(mapped_stage_name) = 'proposal requested'
                    then created_date
                end
            ) as proposal_requested_date,
            min(
                case
                    when lower(mapped_stage_name) = 'proposal sent' then created_date
                end
            ) as proposal_sent_date,
            min(
                case when lower(mapped_stage_name) = 'negotiation' then created_date end
            ) as negotiation_date,
            min(
                case when lower(mapped_stage_name) = 'closed won' then created_date end
            ) as closed_won_date,
            min(
                case when lower(mapped_stage_name) = 'closed lost' then created_date end
            ) as closed_lost_date
        from stage_dates
        group by opportunity_id

    ),

    base_opportunity as (

        select
            o.id as opportunity_id,
            l.lead_id as contact_id,
            o.name as opportunity_name,
            o.created_date as opportunity_date,
            a.record_type_name_c as hub,
            md5(coalesce(o.lead_source, '')) as sales_channel_id,
            md5(coalesce(o.SYSTEM_SUB_TYPE_C, '')) as product_category_id,
            md5(
                coalesce(a.billing_city, '')
                || '|'
                || coalesce(a.billing_state, '')
                || '|'
                || coalesce(a.billing_country, '')
            ) as location_id,
            o.close_date,
            case when lower(dsm.mapped_stage_name) like '%closed won%' then 1 else 0 end as is_won,
            case when lower(dsm.mapped_stage_name) like '%closed%' then 1 else 0 end as is_closed,
            -- o.is_won,
            -- o.is_closed,
            hs.opportunity_date as opp_date,
            hs.proposal_requested_date as proposal_requested_date,
            hs.proposal_sent_date as proposal_sent_date,
            hs.negotiation_date as negotiation_date,
            coalesce(hs.closed_won_date,sd.closed_won_date) as closed_won_date,
            coalesce(hs.closed_lost_date, sd.closed_lost_date)  as closed_lost_date,
            -- coalesce(hs.opportunity_date, cs.opportunity_date) as opp_date,
            -- coalesce(
            --     hs.proposal_requested_date, cs.proposal_requested_date
            -- ) as proposal_requested_date,
            -- coalesce(
            --     hs.proposal_sent_date, cs.proposal_sent_date
            -- ) as proposal_sent_date,
            -- coalesce(hs.negotiation_date, cs.negotiation_date) as negotiation_date,
            -- coalesce(hs.closed_won_date, cs.closed_won_date) as closed_won_date,
            -- coalesce(hs.closed_lost_date, cs.closed_lost_date) as closed_lost_date,
            h.native_stage_name as native_lost_stage,
            h.mapped_stage_name as mapped_lost_stage,
            o.LOSS_REASON_C,
            o.last_modified_date
        from {{ ref('salesforce_opportunity_current') }} o
        left join
            {{ ref('salesforce_lead_current') }} l
            on l.converted_opportunity_id = o.id
            and l.is_active = 1
        left join
            {{ ref('salesforce_account_current') }} a
            on a.account_id = o.account_id
            and a.is_active = 1
        left join {{ ref('salesforce_dim_stage_mapping') }} dsm on dsm.stage_name = o.stage_name
        left join
            hist_stage_dates_by_opp hs
            on hs.opportunity_id = o.id
        left join Last_Stage h on h.opportunity_id = o.id
        left join stage_dates_by_opp sd on o.id = sd.opportunity_id
        
        where
            o.is_active = 1

            {% if is_incremental() %}
                and o.last_modified_date
                > (select max(last_modified_date) from {{ this }})
            {% endif %}

    )
select
    opportunity_id,
    opportunity_name,
    cast(opportunity_date as date) as opportunity_date,
    contact_id,
    case
                when contact_id is null
                then cast(null as date)
                else cast(min(closed_won_date) over (partition by contact_id) as date)
            end as acquisition_date,
    hub,
    sales_channel_id,
    product_category_id,
    location_id,
    CAST(NULL AS VARCHAR) AS sk_location_id,
    LOSS_REASON_C,
    close_date,
    cast(is_closed as Boolean) as is_closed,
    cast(is_won as Boolean) as is_won,

    null as contact_date,


    case
        when is_won = 1
        then
            cast(coalesce(
                proposal_requested_date,
                proposal_sent_date,
                negotiation_date,
                closed_won_date,
                close_date
            ) as date)
        else
            cast(coalesce(
                proposal_requested_date,
                proposal_sent_date,
                negotiation_date,
                closed_lost_date,
                close_date
            ) as date)
    end as proposal_requested_date,

    case
        when is_won = 1
        then cast(coalesce(proposal_sent_date, negotiation_date, closed_won_date, close_date) as date)
        else
            cast(coalesce(proposal_sent_date, negotiation_date, closed_lost_date, close_date) as date)
    end as proposal_sent_date,

    case
        when is_won = 1
        then cast(coalesce(negotiation_date, closed_won_date, close_date) as date)
        else cast(coalesce(negotiation_date, closed_lost_date, close_date) as date)
    end as negotiation_date,

    cast(null as date) as QUALIFIED_LEAD_DATE,
    cast(null as date) as CONTACTED_DATE,

    case
        when is_won = 1 then cast(closed_won_date as date)
    end as 
    closed_won_date,

    case
        when is_won = 0 and is_closed = 1 then cast(closed_lost_date as date)
    end as
    closed_lost_date,
    native_lost_stage,
    mapped_lost_stage,
    null as lead_status,
    cast(null as date) as contact_close_date,
    null as lead_stage,

    'Zeus' as pipeline_name,
    -- last_modified_date,
    concat('SALESFORCE_', '{{ company | upper }}') as source_schema,
    current_timestamp()::timestamp_ntz as gold_load_date

from base_opportunity