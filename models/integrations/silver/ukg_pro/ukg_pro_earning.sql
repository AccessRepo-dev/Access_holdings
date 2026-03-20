{% set company = var("company", "playfly") | lower %}
{% set sourcesystem = var("sourcesystem", "ukg_pro") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "ukg_pro") | lower) in ["ukg_pro"]
        and (var("company", "playfly") | lower) in ["playfly"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["company_id", "employee_id"],
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "EARNING") }}
        {% if is_incremental() %}
            where
                cast(_fivetran_synced as timestamp_ntz) > (
                    select
                        dateadd(
                            day,
                            -1,
                            coalesce(max(_fivetran_synced), '1900-01-01'::timestamp_ntz)
                        )
                    from {{ this }}
                )
        {% endif %}
    ),

    cleaned as (
        select
            trim(id) as id,
            cast(_fivetran_deleted as boolean) as _fivetran_deleted,
            -- cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            trim(notes) as notes,
            cast(
                include_in_deferred_compensation as boolean
            ) as include_in_deferred_compensation,
            cast(
                include_in_earning_accumulation as boolean
            ) as include_in_earning_accumulation,
            cast(is_supplimental_wages as boolean) as is_supplimental_wages,
            cast(block_local_income_tax as boolean) as block_local_income_tax,
            cast(
                include_in_registered_retirement_savings_plan as boolean
            ) as include_in_registered_retirement_savings_plan,
            cast(excel_in_total_hours as boolean) as excel_in_total_hours,
            cast(schedule_supplemental as boolean) as schedule_supplemental,
            cast(
                include_in_miscellaneous_earning_2 as boolean
            ) as include_in_miscellaneous_earning_2,
            cast(
                include_in_miscellaneous_earning_1 as boolean
            ) as include_in_miscellaneous_earning_1,
            cast(
                include_in_miscellaneous_earning_4 as boolean
            ) as include_in_miscellaneous_earning_4,
            cast(
                include_in_miscellaneous_earning_3 as boolean
            ) as include_in_miscellaneous_earning_3,
            cast(
                include_in_miscellaneous_earning_6 as boolean
            ) as include_in_miscellaneous_earning_6,
            cast(
                include_in_miscellaneous_earning_5 as boolean
            ) as include_in_miscellaneous_earning_5,
            cast(include_in_union_dues_hours as boolean) as include_in_union_dues_hours,
            cast(
                include_in_hours_accumulation as boolean
            ) as include_in_hours_accumulation,
            cast(
                include_in_shift_diffrential as boolean
            ) as include_in_shift_diffrential,
            cast(flat_hours as float) as flat_hours,
            cast(include_in_union_dues as boolean) as include_in_union_dues,
            trim(time_clock_code) as time_clock_code,
            cast(include_in_retro_pay as boolean) as include_in_retro_pay,
            trim(calculation_rule) as calculation_rule,
            trim(verification_type_description) as verification_type_description,
            trim(exempt_from_earned_income_hours) as exempt_from_earned_income_hours,
            trim(country_code) as country_code,
            cast(block_state_income_tax as boolean) as block_state_income_tax,
            cast(include_in_benefit_hours as boolean) as include_in_benefit_hours,
            cast(
                include_in_health_care_hours as boolean
            ) as include_in_health_care_hours,
            trim(include_in_accruals) as include_in_accruals,
            cast(reduce_regular_dollars as boolean) as reduce_regular_dollars,
            trim(report_category) as report_category,
            cast(
                include_flsa_average_pay_rate as boolean
            ) as include_flsa_average_pay_rate,
            cast(
                include_in_deferred_compensation_hours as boolean
            ) as include_in_deferred_compensation_hours,
            cast(monthly_pay_period_4 as boolean) as monthly_pay_period_4,
            cast(monthly_pay_period_3 as boolean) as monthly_pay_period_3,
            trim(verification_type_code) as verification_type_code,
            cast(monthly_pay_period_2 as boolean) as monthly_pay_period_2,
            cast(monthly_pay_period_1 as boolean) as monthly_pay_period_1,
            cast(use_deduction_offset as boolean) as use_deduction_offset,
            cast(is_productive_time as boolean) as is_productive_time,
            cast(amount as float) as amount,
            cast(reduce_regular_hours as boolean) as reduce_regular_hours,
            cast(include_in_manual_check as boolean) as include_in_manual_check,
            trim(tax_category) as tax_category,
            cast(display_in_pay_data_entry as boolean) as display_in_pay_data_entry,
            trim(long_description) as long_description,
            cast(monthly_pay_period_5 as boolean) as monthly_pay_period_5,
            cast(
                include_in_registered_pension_plan as boolean
            ) as include_in_registered_pension_plan,
            trim(stub_description) as stub_description,
            cast(include_in_allocations as boolean) as include_in_allocations,
            cast(block_federal_income_tax as boolean) as block_federal_income_tax,
            cast(
                include_in_pension_accumulation as boolean
            ) as include_in_pension_accumulation,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
