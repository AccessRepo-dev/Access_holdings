{% set company = var('company') %}

{{ config(
    database = get_target_database(company),
    materialized = 'table',
    alias = 'FACT_WAGWAY_GINGR_TRANSACTION'
) }}

with cte1 as (
    select distinct
        a.id as invoice_id,
        a.owner_id,
        a.subtotal,
        a.tax_amount,
        a.discounts_total,
        a.total,
        a.payment_amount,
        to_timestamp(cast(a.create_stamp as int)) as order_date,
        case
            when a.total = a.payment_amount then 'closed'
            when a.payment_amount = 0 and a.total <> a.payment_amount then 'open'
            when a.total > a.payment_amount and a.payment_amount <> 0 then 'partially closed'
        end as status,
        b.price as service_price,
        b.discounts_total as service_discounts_total,
        b.tax_amount as service_tax_amount,
        b.is_returned,
        case
            when c.code ilike '%packages %'
                then right(c.code, length(c.code) - position('|', c.code) - 1)
            when c.code ilike '%memberships%'
                then 'Memberships'
            when c.code ilike '%|%'
                then left(c.code, position('|', c.code)-2)
            else c.code
        end as code,
        concat(
            trim(
                case 
                    when d.property_club_c ilike '%Lakeview%' then '1'
                    when d.property_club_c ilike '%Gold Coast%' then '2'
                    when d.property_club_c ilike '%River North%' then '3'
                    when d.property_club_c ilike '%Wicker Park%' then '4'
                    when d.property_club_c ilike '%South Loop%' then '5'
                    when d.property_club_c ilike '%Streeterville%' then '6'
                    when d.property_club_c ilike '%Lakeshore East%' then '7'
                    when d.property_club_c ilike '%DoBro%' then '8'
                    when d.property_club_c ilike '%Williamsburg%' then '9'
                end
            ),
            '-pupspetclub'
        ) as sk_location_id,
        case
            when length(regexp_replace(concat('+1', regexp_replace(e.cell_phone, '[^0-9]', '')), '[^0-9]', '')) = 10
                then concat('+1', regexp_replace(concat('+1', regexp_replace(e.cell_phone, '[^0-9]', '')), '[^0-9]', ''))
            when length(regexp_replace(concat('+1', regexp_replace(e.cell_phone, '[^0-9]', '')), '[^0-9]', '')) = 11
                and left(regexp_replace(concat('+1', regexp_replace(e.cell_phone, '[^0-9]', '')), '[^0-9]', ''), 1) = '1'
                then concat('+', regexp_replace(concat('+1', regexp_replace(e.cell_phone, '[^0-9]', '')), '[^0-9]', ''))
            else concat('+', regexp_replace(concat('+1', regexp_replace(e.cell_phone, '[^0-9]', '')), '[^0-9]', ''))
        end as phone_number
    from {{ get_silver_source('wagway', 'gingr_pos_transaction_items_audit') }} b
    left join {{ get_silver_source('wagway', 'gingr_pos_transactions') }} a on a.id = b.pos_transaction_id
    left join {{ get_silver_source('wagway', 'gingr_account_codes') }} c on c.id = b.account_code_id
    left join {{ get_silver_source('wagway', 'gingr_owners') }} e on e.id = a.owner_id
    left join {{ get_silver_source('wagway', 'hubspot_deal') }} d on d.property_invoice_id = a.id
),
cte2 as (
    select 
        *,
        row_number() over (partition by owner_id order by order_date) as order_no
    from cte1
)

select *
from cte2
