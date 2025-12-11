{{
    config(
        database=get_target_database("wagway"),
        materialized="table",
        alias="FACT_WAGWAY_TRANSACTION",
    )
}}

select
    a.pos_transaction_id as invoice_id,
    a.source_db,
    a.price as service_price,
    a.account_code_id,
    b.owner_id,
    b.total,
    b.payment_amount,
    CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp)  as order_date,
    concat(b.location_id, '-', b.source_db) as sk_location_id,

    min(CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp) ) over (
        partition by concat(b.owner_id, b.source_db)
    ) as acquisition_date,

    datediff(
        month,
        min(CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp) ) over (
            partition by concat(b.owner_id, b.source_db)
        ),
        CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp) 
    ) as months_since_acquisition,

    datediff(
        month,
        lag(CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp) ) over (
            partition by concat(b.owner_id, b.source_db)
            order by CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp) 
        ),
        CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp) 
    ) as diff_between_orders,

    max(CONVERT_TIMEZONE('UTC', 'America/New_York', b.create_stamp) ) over (
        partition by concat(b.owner_id, b.source_db)
    ) as last_order_date,
    c.code,

    convert_timezone(
        'America/New_York', current_timestamp()::timestamp_ntz
    ) as last_refresh_date

from {{ get_silver_source('wagway', 'gingr_pos_transaction_items') }}  a
left join
    {{ get_silver_source('wagway', 'gingr_pos_transactions') }}b
    on concat(a.pos_transaction_id, a.source_db) = concat(b.id, b.source_db)
    and b.delete_indicator = 0
left join
    {{ get_silver_source('wagway', 'gingr_account_codes') }}c
    on concat(a.account_code_id, a.source_db) = concat(c.id, c.source_db)
    and c.delete_indicator = 0
left join
    {{ get_silver_source('wagway', 'gingr_reservations') }} d
    on concat(a.pos_transaction_id, a.source_db) = concat(d.id, d.source_db)
    and d.delete_indicator = 0
where b.total = b.payment_amount and a.delete_indicator = 0
