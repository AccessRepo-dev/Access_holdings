{% set company = var('company') %}

{{ config(
    enabled = (var('company') | lower) == 'wagway',
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_ACCOUNT_CALL_LOG'
) }}

----------------------------------------------------------
-- CTE1:  Gingr phone numbers for matching
----------------------------------------------------------
with cte1 as (
    select
        id as owner_id,
        case
            when length(regexp_replace(concat('+1', regexp_replace(cell_phone, '[^0-9]', '')), '[^0-9]', '')) = 10
                then concat('+1', regexp_replace(concat('+1', regexp_replace(cell_phone, '[^0-9]', '')), '[^0-9]', ''))
            when length(regexp_replace(concat('+1', regexp_replace(cell_phone, '[^0-9]', '')), '[^0-9]', '')) = 11
                and left(regexp_replace(concat('+1', regexp_replace(cell_phone, '[^0-9]', '')), '[^0-9]', ''), 1) = '1'
                then concat('+', regexp_replace(concat('+1', regexp_replace(cell_phone, '[^0-9]', '')), '[^0-9]', ''))
            else concat('+', regexp_replace(concat('+1', regexp_replace(cell_phone, '[^0-9]', '')), '[^0-9]', ''))
        end as clean_number
    from {{ get_silver_source('wagway', 'gingr_owners') }}
),

----------------------------------------------------------
-- CTE2: Main call log with hubspot + ringcentral + gingr
----------------------------------------------------------
cte2 as (
    select distinct
        a.id,
        a.start_time,
        a.duration,
        a.duration_ms,
        a.type,
        a.internal_type,
        a.direction,
        a.action,
        a.result,
        a.reason,
        a.reason_description,
        a.account_id,
        a.session_id,
        a.from_phone_number,
        a.from_extension_number,
        a.from_extension_id,
        a.from_location,
        a.from_name,
        a.from_dialed_phone_number,
        a.to_phone_number,
        a.to_extension_number,
        a.to_extension_id,
        a.to_location,
        a.to_name,
        a.to_dialed_phone_number,
        a.extension_id,
        'PUPS Pet Club' as company,

        -- PROPERTY_PHONE_NUMBER
        case 
            when a.direction = 'Inbound' then a.from_phone_number
            else a.to_phone_number
        end as property_phone_number,

        -- LOCATION (fallback to directory)
        coalesce(
            case when a.direction = 'Outbound' then a.from_name else a.to_name end,
            concat(c.first_name, ' ', c.last_name)
        ) as location,

        -- PROPERTY
        case when a.direction = 'Inbound' then a.from_name else a.to_name end as property,

        -- HOURS
        a.duration_ms / 360000.0 as hours,

        -- CALLBACK
        case
            when a.direction = 'Inbound'
             and a.result = 'Missed'
             and not exists (
                select 1
                from {{ get_silver_source('wagway', 'ringcentral_account_call_log') }} b
                where a.from_phone_number = b.to_phone_number
                  and b.start_time > a.start_time
            )
            then 0
            else 1
        end as callback,

        -- FORWARDED
        case
            when (
                a.to_name ilike '%fwd%' or a.from_name ilike '%fwd%'
                or (
                    a.direction = 'Inbound'
                    and a.from_phone_number is null
                    and replace(a.from_name, ' ', '') in (
                        select replace(concat(first_name, last_name), ' ', '')
                        from {{ get_silver_source('wagway', 'ringcentral_company_directory') }}
                    )
                )
                or (
                    a.direction = 'Outbound'
                    and a.to_phone_number is null
                    and replace(a.to_name, ' ', '') in (
                        select replace(concat(first_name, last_name), ' ', '')
                        from {{ get_silver_source('wagway', 'ringcentral_company_directory') }}
                    )
                )
            )
            then 1 else 0
        end as forwarded,

        -- HubSpot property club
        min(e.property_club_c) over (
            partition by 
                case when a.direction = 'Inbound' then a.from_phone_number else a.to_phone_number end
            order by f.property_createdate
        ) as property_club_c,

        -- GINGR match
        g.owner_id as customer_id

    from {{ get_silver_source('wagway', 'ringcentral_account_call_log') }} a

    left join {{ get_silver_source('wagway', 'ringcentral_company_directory_phone_number') }} d
        on d.phone_number = case
            when a.direction = 'Outbound' then a.from_phone_number
            else a.to_phone_number
        end

    left join {{ get_silver_source('wagway', 'ringcentral_company_directory') }} c
        on c.id = d.company_directory_id

    left join {{ get_silver_source('wagway', 'hubspot_contact') }} e
        on coalesce(
            e.property_hs_calculated_phone_number,
            e.property_hs_calculated_mobile_number
        ) = case when a.direction = 'Outbound' then a.to_phone_number else a.from_phone_number end

    left join {{ get_silver_source('wagway', 'hubspot_deal_contact') }} b
        on e.id = b.contact_id

    left join {{ get_silver_source('wagway', 'hubspot_deal') }} f
        on b.deal_id = f.deal_id

    left join cte1 g 
        on case 
            when a.direction = 'Inbound' then a.from_phone_number
            else a.to_phone_number 
        end = g.clean_number
),

----------------------------------------------------------
-- Final output with revenue cte
----------------------------------------------------------
revenue_cte as (
    select
        owner_id,
        sum(total) as revenue
    from {{ get_silver_source('wagway', 'gingr_pos_transactions') }}
    group by owner_id
)

select
    a.*,
    case when a.customer_id is not null then 1 else 0 end as is_in_gingr,
    coalesce(r.revenue, 0) as revenue
from cte2 a
left join revenue_cte r on a.customer_id = r.owner_id
