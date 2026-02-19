{% set company = var("company", "zeus") | lower %}
{% set sourcesystem = var("sourcesystem", "adp_workforce_now") | lower %}

{{
    config(
        enabled=(var("sourcesystem", "adp_workforce_now") | lower) in ["adp_workforce_now"]
        and (var("company", "zeus") | lower) in ["zeus"],
        database=get_target_database(company),
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="ID",
    )
}}

with
    source_data as (
        select *
        from {{ get_raw_source(company, sourcesystem, "WORK_ASSIGNMENT_HISTORY") }}
        {% if is_incremental() %}
            where
                _fivetran_synced > (
                    select
                        dateadd(day, -3, coalesce(max(_fivetran_synced), '1900-01-01'))
                    from {{ this }}
                )
        {% else %} where 1 = 1
        {% endif %}

    ),

    cleaned as (
        select
            trim(coalesce(id, '')) as id,
            trim(coalesce(worker_id, '')) as worker_id,
            coalesce(primary_indicator, false) as primary_indicator,
            coalesce(worker_probation_indicator, false) as worker_probation_indicator,
            coalesce(vip_indicator, false) as vip_indicator,
            coalesce(executive_indicator, false) as executive_indicator,
            coalesce(officer_indicator, false) as officer_indicator,
            coalesce(
                management_position_indicator, false
            ) as management_position_indicator,
            coalesce(
                highly_compensated_indicator, false
            ) as highly_compensated_indicator,
            coalesce(stock_owner_indicator, false) as stock_owner_indicator,
            coalesce(voluntary_indicator, false) as voluntary_indicator,
            cast(offer_extension_date as date) as offer_extension_date,
            cast(offer_acceptance_date as date) as offer_acceptance_date,
            cast(hire_date as date) as hire_date,
            cast(seniority_date as date) as seniority_date,
            cast(expected_start_date as date) as expected_start_date,
            cast(actual_start_date as date) as actual_start_date,
            cast(termination_date as date) as termination_date,
            cast(expected_termination_date as date) as expected_termination_date,
            cast(next_pay_grade_step_date as date) as next_pay_grade_step_date,
            trim(coalesce(legal_entity_id, '')) as legal_entity_id,
            trim(coalesce(job_title, '')) as job_title,
            trim(coalesce(position_id, '')) as position_id,
            trim(coalesce(position_title, '')) as position_title,
            trim(coalesce(payroll_group_code, '')) as payroll_group_code,
            trim(coalesce(payroll_schedule_group_id, '')) as payroll_schedule_group_id,
            trim(coalesce(payroll_file_number, '')) as payroll_file_number,
            trim(coalesce(payroll_region_code, '')) as payroll_region_code,
            trim(
                coalesce(minimum_pay_grade_step_duration, '')
            ) as minimum_pay_grade_step_duration,
            cast(stock_owner_percentage as float) as stock_owner_percentage,
            cast(full_time_equivalence_ratio as float) as full_time_equivalence_ratio,
            cast(compa_ratio as float) as compa_ratio,
            cast(
                geographic_pay_differential_percentage as float
            ) as geographic_pay_differential_percentage,
            trim(assignment_status_short_name) as assignment_status_short_name,
            trim(assignment_status_long_name) as assignment_status_long_name,
            trim(assignment_status_subdivision_type) as assignment_status_subdivision_type,
            cast(
                assignment_status_effective_date as date
            ) as assignment_status_effective_date,
            trim(assignment_status_reason_short_name) as assignment_status_reason_short_name,
            trim(assignment_status_reason_long_name) as assignment_status_reason_long_name,
            trim(assignment_status_reason_subdivision_type)as assignment_status_reason_subdivision_type,
            cast(
                assignment_status_reason_effective_date as date
            ) as assignment_status_reason_effective_date,
            trim(coalesce(assignment_status_value, '')) as assignment_status_value,
            trim(coalesce(assignment_status_reason, '')) as assignment_status_reason,
            cast(probation_period_start_date as date) as probation_period_start_date,
            cast(probation_period_end_date as date) as probation_period_end_date,
            trim(worker_type_short_name) as worker_type_short_name,
            trim(worker_type_long_name) as worker_type_long_name,
            trim(
                coalesce(worker_type_subdivision_type, '')
            ) as worker_type_subdivision_type,
            cast(worker_type_effective_date as date) as worker_type_effective_date,
            trim(
                coalesce(assignment_term_short_name, '')
            ) as assignment_term_short_name,
            trim(coalesce(assignment_term_long_name, '')) as assignment_term_long_name,
            trim(
                coalesce(assignment_term_subdivision_type, '')
            ) as assignment_term_subdivision_type,
            cast(
                assignment_term_effective_date as date
            ) as assignment_term_effective_date,
            trim(coalesce(work_level_short_name, '')) as work_level_short_name,
            trim(coalesce(work_level_long_name, '')) as work_level_long_name,
            trim(
                coalesce(work_level_subdivision_type, '')
            ) as work_level_subdivision_type,
            cast(work_level_effective_date as date) as work_level_effective_date,
            trim(
                coalesce(nationality_context_short_name, '')
            ) as nationality_context_short_name,
            trim(
                coalesce(nationality_context_long_name, '')
            ) as nationality_context_long_name,
            trim(
                coalesce(nationality_context_subdivision_type, '')
            ) as nationality_context_subdivision_type,
            cast(
                nationality_context_effective_date as date
            ) as nationality_context_effective_date,
            trim(coalesce(executive_type_short_name, '')) as executive_type_short_name,
            trim(coalesce(executive_type_long_name, '')) as executive_type_long_name,
            trim(
                coalesce(executive_type_subdivision_type, '')
            ) as executive_type_subdivision_type,
            cast(
                executive_type_effective_date as date
            ) as executive_type_effective_date,
            trim(coalesce(officer_type_short_name, '')) as officer_type_short_name,
            trim(coalesce(officer_type_long_name, '')) as officer_type_long_name,
            trim(
                coalesce(officer_type_subdivision_type, '')
            ) as officer_type_subdivision_type,
            cast(officer_type_effective_date as date) as officer_type_effective_date,
            trim(
                coalesce(highly_compensated_type_short_name, '')
            ) as highly_compensated_type_short_name,
            trim(
                coalesce(highly_compensated_type_long_name, '')
            ) as highly_compensated_type_long_name,
            trim(
                coalesce(highly_compensated_type_subdivision_type, '')
            ) as highly_compensated_type_subdivision_type,
            cast(
                highly_compensated_type_effective_date as date
            ) as highly_compensated_type_effective_date,
            trim(coalesce(work_shift_short_name, '')) as work_shift_short_name,
            trim(coalesce(work_shift_long_name, '')) as work_shift_long_name,
            trim(
                coalesce(work_shift_subdivision_type, '')
            ) as work_shift_subdivision_type,
            cast(work_shift_effective_date as date) as work_shift_effective_date,
            trim(
                coalesce(work_arrangement_short_name, '')
            ) as work_arrangement_short_name,
            trim(
                coalesce(work_arrangement_long_name, '')
            ) as work_arrangement_long_name,
            trim(
                coalesce(work_arrangement_subdivision_type, '')
            ) as work_arrangement_subdivision_type,
            cast(
                work_arrangement_effective_date as date
            ) as work_arrangement_effective_date,
            trim(
                coalesce(remuneration_basis_short_name, '')
            ) as remuneration_basis_short_name,
            trim(
                coalesce(remuneration_basis_long_name, '')
            ) as remuneration_basis_long_name,
            trim(
                coalesce(remuneration_basis_subdivision_type, '')
            ) as remuneration_basis_subdivision_type,
            cast(
                remuneration_basis_effective_date as date
            ) as remuneration_basis_effective_date,
            trim(coalesce(pay_cycle_short_name, '')) as pay_cycle_short_name,
            trim(coalesce(pay_cycle_long_name, '')) as pay_cycle_long_name,
            trim(
                coalesce(pay_cycle_subdivision_type, '')
            ) as pay_cycle_subdivision_type,
            cast(pay_cycle_effective_date as date) as pay_cycle_effective_date,
            trim(coalesce(job_short_name, '')) as job_short_name,
            trim(coalesce(job_long_name, '')) as job_long_name,
            trim(coalesce(job_subdivision_type, '')) as job_subdivision_type,
            cast(job_effective_date as date) as job_effective_date,
            trim(coalesce(job_function_short_name, '')) as job_function_short_name,
            trim(coalesce(job_function_long_name, '')) as job_function_long_name,
            trim(
                coalesce(job_function_subdivision_type, '')
            ) as job_function_subdivision_type,
            cast(job_function_effective_date as date) as job_function_effective_date,
            trim(
                coalesce(payroll_processing_status_short_name, '')
            ) as payroll_processing_status_short_name,
            trim(
                coalesce(payroll_processing_status_long_name, '')
            ) as payroll_processing_status_long_name,
            trim(
                coalesce(payroll_processing_status_subdivision_type, '')
            ) as payroll_processing_status_subdivision_type,
            cast(
                payroll_processing_status_effective_date as date
            ) as payroll_processing_status_effective_date,
            trim(coalesce(pay_scale_short_name, '')) as pay_scale_short_name,
            trim(coalesce(pay_scale_long_name, '')) as pay_scale_long_name,
            trim(
                coalesce(pay_scale_subdivision_type, '')
            ) as pay_scale_subdivision_type,
            cast(pay_scale_effective_date as date) as pay_scale_effective_date,
            trim(coalesce(pay_grade_short_name, '')) as pay_grade_short_name,
            trim(coalesce(pay_grade_long_name, '')) as pay_grade_long_name,
            trim(
                coalesce(pay_grade_subdivision_type, '')
            ) as pay_grade_subdivision_type,
            cast(pay_grade_effective_date as date) as pay_grade_effective_date,
            trim(coalesce(pay_grade_step_short_name, '')) as pay_grade_step_short_name,
            trim(coalesce(pay_grade_step_long_name, '')) as pay_grade_step_long_name,
            trim(
                coalesce(pay_grade_step_subdivision_type, '')
            ) as pay_grade_step_subdivision_type,
            cast(
                pay_grade_step_effective_date as date
            ) as pay_grade_step_effective_date,
            cast(
                pay_grade_step_pay_amount_value as number
            ) as pay_grade_step_pay_amount_value,
            cast(
                pay_grade_step_pay_base_multiplier_value as number
            ) as pay_grade_step_pay_base_multiplier_value,
            trim(
                coalesce(pay_grade_step_pay_currency_code, '')
            ) as pay_grade_step_pay_currency_code,
            trim(
                coalesce(pay_grade_step_pay_unit_short_name, '')
            ) as pay_grade_step_pay_unit_short_name,
            trim(
                coalesce(pay_grade_step_pay_unit_long_name, '')
            ) as pay_grade_step_pay_unit_long_name,
            trim(
                coalesce(pay_grade_step_pay_unit_subdivision_type, '')
            ) as pay_grade_step_pay_unit_subdivision_type,
            cast(
                pay_grade_step_pay_unit_effective_date as date
            ) as pay_grade_step_pay_unit_effective_date,
            trim(
                coalesce(pay_grade_step_pay_base_unit_short_name, '')
            ) as pay_grade_step_pay_base_unit_short_name,
            trim(
                coalesce(pay_grade_step_pay_base_unit_long_name, '')
            ) as pay_grade_step_pay_base_unit_long_name,
            trim(
                coalesce(pay_grade_step_pay_base_unit_subdivision_type, '')
            ) as pay_grade_step_pay_base_unit_subdivision_type,
            cast(
                pay_grade_step_pay_base_unit_effective_date as date
            ) as pay_grade_step_pay_base_unit_effective_date,
            trim(coalesce(pay_grade_step_pay_unit, '')) as pay_grade_step_pay_unit,
            trim(
                coalesce(pay_grade_step_pay_base_unit, '')
            ) as pay_grade_step_pay_base_unit,
            trim(
                coalesce(geographic_pay_differential_short_name, '')
            ) as geographic_pay_differential_short_name,
            trim(
                coalesce(geographic_pay_differential_long_name, '')
            ) as geographic_pay_differential_long_name,
            trim(
                coalesce(geographic_pay_differential_subdivision_type, '')
            ) as geographic_pay_differential_subdivision_type,
            cast(
                geographic_pay_differential_effective_date as date
            ) as geographic_pay_differential_effective_date,
            trim(coalesce(wage_law_coverage_value, '')) as wage_law_coverage_value,
            trim(coalesce(labor_union_short_name, '')) as labor_union_short_name,
            trim(coalesce(labor_union_long_name, '')) as labor_union_long_name,
            trim(
                coalesce(labor_union_subdivision_type, '')
            ) as labor_union_subdivision_type,
            cast(labor_union_effective_date as date) as labor_union_effective_date,
            cast(labor_union_seniority_date as date) as labor_union_seniority_date,
            trim(coalesce(labor_union_value, '')) as labor_union_value,
            trim(
                coalesce(bargaining_unit_short_name, '')
            ) as bargaining_unit_short_name,
            trim(coalesce(bargaining_unit_long_name, '')) as bargaining_unit_long_name,
            trim(
                coalesce(bargaining_unit_subdivision_type, '')
            ) as bargaining_unit_subdivision_type,
            cast(
                bargaining_unit_effective_date as date
            ) as bargaining_unit_effective_date,
            cast(
                bargaining_unit_seniority_date as date
            ) as bargaining_unit_seniority_date,
            trim(coalesce(bargaining_unit_value, '')) as bargaining_unit_value,
            cast(
                standard_hour_hours_quantity as number
            ) as standard_hour_hours_quantity,
            trim(
                coalesce(standard_hour_unit_short_name, '')
            ) as standard_hour_unit_short_name,
            trim(
                coalesce(standard_hour_unit_long_name, '')
            ) as standard_hour_unit_long_name,
            trim(
                coalesce(standard_hour_unit_subdivision_type, '')
            ) as standard_hour_unit_subdivision_type,
            cast(
                standard_hour_unit_effective_date as date
            ) as standard_hour_unit_effective_date,
            trim(coalesce(standard_hour_unit, '')) as standard_hour_unit,
            cast(
                standard_pay_period_hour_hours_quantity as number
            ) as standard_pay_period_hour_hours_quantity,
            trim(
                coalesce(standard_pay_period_hour_unit_short_name, '')
            ) as standard_pay_period_hour_unit_short_name,
            trim(
                coalesce(standard_pay_period_hour_unit_long_name, '')
            ) as standard_pay_period_hour_unit_long_name,
            trim(
                coalesce(standard_pay_period_hour_unit_subdivision_type, '')
            ) as standard_pay_period_hour_unit_subdivision_type,
            cast(
                standard_pay_period_hour_unit_effective_date as date
            ) as standard_pay_period_hour_unit_effective_date,
            trim(
                coalesce(standard_pay_period_hour_unit, '')
            ) as standard_pay_period_hour_unit,
            trim(
                coalesce(home_work_location_name_short_name, '')
            ) as home_work_location_name_short_name,
            trim(
                coalesce(home_work_location_name_long_name, '')
            ) as home_work_location_name_long_name,
            trim(
                coalesce(home_work_location_name_subdivision_type, '')
            ) as home_work_location_name_subdivision_type,
            cast(
                home_work_location_name_effective_date as date
            ) as home_work_location_name_effective_date,
            trim(
                coalesce(home_work_location_address_attention_of_name, '')
            ) as home_work_location_address_attention_of_name,
            trim(
                coalesce(home_work_location_address_care_of_name, '')
            ) as home_work_location_address_care_of_name,
            trim(
                coalesce(home_work_location_address_line_one, '')
            ) as home_work_location_address_line_one,
            trim(
                coalesce(home_work_location_address_line_two, '')
            ) as home_work_location_address_line_two,
            trim(
                coalesce(home_work_location_address_line_three, '')
            ) as home_work_location_address_line_three,
            trim(
                coalesce(home_work_location_address_line_four, '')
            ) as home_work_location_address_line_four,
            trim(
                coalesce(home_work_location_address_line_five, '')
            ) as home_work_location_address_line_five,
            trim(
                coalesce(home_work_location_address_building_number, '')
            ) as home_work_location_address_building_number,
            trim(
                coalesce(home_work_location_address_building_name, '')
            ) as home_work_location_address_building_name,
            trim(
                coalesce(home_work_location_address_block_name, '')
            ) as home_work_location_address_block_name,
            trim(
                coalesce(home_work_location_address_street_name, '')
            ) as home_work_location_address_street_name,
            trim(
                coalesce(home_work_location_address_city_name, '')
            ) as home_work_location_address_city_name,
            trim(
                coalesce(home_work_location_address_country_code, '')
            ) as home_work_location_address_country_code,
            trim(
                coalesce(home_work_location_address_postal_code, '')
            ) as home_work_location_address_postal_code,
            trim(
                coalesce(home_work_location_address_unit, '')
            ) as home_work_location_address_unit,
            trim(
                coalesce(home_work_location_address_floor, '')
            ) as home_work_location_address_floor,
            trim(
                coalesce(home_work_location_address_stair_case, '')
            ) as home_work_location_address_stair_case,
            trim(
                coalesce(home_work_location_address_door, '')
            ) as home_work_location_address_door,
            trim(
                coalesce(home_work_location_address_post_office_box, '')
            ) as home_work_location_address_post_office_box,
            trim(
                coalesce(home_work_location_address_delivery_point, '')
            ) as home_work_location_address_delivery_point,
            trim(
                coalesce(home_work_location_address_plot_id, '')
            ) as home_work_location_address_plot_id,
            trim(
                coalesce(home_work_location_address_formatted_birth_place, '')
            ) as home_work_location_address_formatted_birth_place,
            coalesce(
                home_work_location_address_same_as_address_indicator, false
            ) as home_work_location_address_same_as_address_indicator,
            trim(
                coalesce(home_work_location_address_name_short_name, '')
            ) as home_work_location_address_name_short_name,
            trim(
                coalesce(home_work_location_address_name_long_name, '')
            ) as home_work_location_address_name_long_name,
            trim(
                coalesce(home_work_location_address_name_subdivision_type, '')
            ) as home_work_location_address_name_subdivision_type,
            cast(
                home_work_location_address_name_effective_date as date
            ) as home_work_location_address_name_effective_date,
            trim(
                coalesce(home_work_location_address_script_short_name, '')
            ) as home_work_location_address_script_short_name,
            trim(
                coalesce(home_work_location_address_script_long_name, '')
            ) as home_work_location_address_script_long_name,
            trim(
                coalesce(home_work_location_address_script_subdivision_type, '')
            ) as home_work_location_address_script_subdivision_type,
            cast(
                home_work_location_address_script_effective_date as date
            ) as home_work_location_address_script_effective_date,
            trim(
                coalesce(home_work_location_address_street_type_short_name, '')
            ) as home_work_location_address_street_type_short_name,
            trim(
                coalesce(home_work_location_address_street_type_long_name, '')
            ) as home_work_location_address_street_type_long_name,
            trim(
                coalesce(home_work_location_address_street_type_subdivision_type, '')
            ) as home_work_location_address_street_type_subdivision_type,
            cast(
                home_work_location_address_street_type_effective_date as date
            ) as home_work_location_address_street_type_effective_date,
            trim(
                coalesce(home_work_location_address_type_short_name, '')
            ) as home_work_location_address_type_short_name,
            trim(
                coalesce(home_work_location_address_type_long_name, '')
            ) as home_work_location_address_type_long_name,
            trim(
                coalesce(home_work_location_address_type_subdivision_type, '')
            ) as home_work_location_address_type_subdivision_type,
            cast(
                home_work_location_address_type_effective_date as date
            ) as home_work_location_address_type_effective_date,
            cast(
                home_work_location_address_geo_coordinate_latitude as float
            ) as home_work_location_address_geo_coordinate_latitude,
            cast(
                home_work_location_address_geo_coordinate_longitude as float
            ) as home_work_location_address_geo_coordinate_longitude,
            trim(
                coalesce(home_work_location_address_item_id, '')
            ) as home_work_location_address_item_id,
            trim(
                coalesce(home_work_location_address_country_subdivision_level_1, '')
            ) as home_work_location_address_country_subdivision_level_1,
            trim(
                coalesce(home_work_location_address_country_subdivision_level_2, '')
            ) as home_work_location_address_country_subdivision_level_2,
            trim(
                coalesce(home_work_location_address_street_type, '')
            ) as home_work_location_address_street_type,
            trim(
                coalesce(home_work_location_address_name, '')
            ) as home_work_location_address_name,
            trim(
                coalesce(home_work_location_address_type, '')
            ) as home_work_location_address_type,
            trim(
                coalesce(home_work_location_address_script, '')
            ) as home_work_location_address_script,
            trim(coalesce(home_work_location_name, '')) as home_work_location_name,
            trim(
                coalesce(annual_benefit_base_rate_name_short_name, '')
            ) as annual_benefit_base_rate_name_short_name,
            trim(
                coalesce(annual_benefit_base_rate_name_long_name, '')
            ) as annual_benefit_base_rate_name_long_name,
            trim(
                coalesce(annual_benefit_base_rate_name_subdivision_type, '')
            ) as annual_benefit_base_rate_name_subdivision_type,
            cast(
                annual_benefit_base_rate_name_effective_date as date
            ) as annual_benefit_base_rate_name_effective_date,
            trim(
                coalesce(annual_benefit_base_rate_base_unit_short_name, '')
            ) as annual_benefit_base_rate_base_unit_short_name,
            trim(
                coalesce(annual_benefit_base_rate_base_unit_long_name, '')
            ) as annual_benefit_base_rate_base_unit_long_name,
            trim(
                coalesce(annual_benefit_base_rate_base_unit_subdivision_type, '')
            ) as annual_benefit_base_rate_base_unit_subdivision_type,
            cast(
                annual_benefit_base_rate_base_unit_effective_date as date
            ) as annual_benefit_base_rate_base_unit_effective_date,
            cast(
                annual_benefit_base_rate_amount_value as number
            ) as annual_benefit_base_rate_amount_value,
            cast(
                annual_benefit_base_rate_percentage_value as number
            ) as annual_benefit_base_rate_percentage_value,
            trim(
                coalesce(annual_benefit_base_rate_currency_code, '')
            ) as annual_benefit_base_rate_currency_code,
            trim(
                coalesce(annual_benefit_base_rate_name, '')
            ) as annual_benefit_base_rate_name,
            trim(
                coalesce(annual_benefit_base_rate_base_unit, '')
            ) as annual_benefit_base_rate_base_unit,
            cast(pay_grade_rate_amount_value as number) as pay_grade_rate_amount_value,
            cast(
                pay_grade_rate_base_multiplier_value as number
            ) as pay_grade_rate_base_multiplier_value,
            trim(
                coalesce(pay_grade_rate_currency_code, '')
            ) as pay_grade_rate_currency_code,
            trim(
                coalesce(pay_grade_rate_unit_short_name, '')
            ) as pay_grade_rate_unit_short_name,
            trim(
                coalesce(pay_grade_rate_unit_long_name, '')
            ) as pay_grade_rate_unit_long_name,
            trim(
                coalesce(pay_grade_rate_unit_subdivision_type, '')
            ) as pay_grade_rate_unit_subdivision_type,
            cast(
                pay_grade_rate_unit_effective_date as date
            ) as pay_grade_rate_unit_effective_date,
            trim(
                coalesce(pay_grade_rate_base_unit_short_name, '')
            ) as pay_grade_rate_base_unit_short_name,
            trim(
                coalesce(pay_grade_rate_base_unit_long_name, '')
            ) as pay_grade_rate_base_unit_long_name,
            trim(
                coalesce(pay_grade_rate_base_unit_subdivision_type, '')
            ) as pay_grade_rate_base_unit_subdivision_type,
            cast(
                pay_grade_rate_base_unit_effective_date as date
            ) as pay_grade_rate_base_unit_effective_date,
            trim(coalesce(pay_grade_rate_unit, '')) as pay_grade_rate_unit,
            trim(coalesce(pay_grade_rate_base_unit, '')) as pay_grade_rate_base_unit,
            trim(coalesce(worker_type, '')) as worker_type,
            trim(coalesce(assignment_term, '')) as assignment_term,
            trim(coalesce(work_level, '')) as work_level,
            trim(coalesce(nationality_context, '')) as nationality_context,
            trim(coalesce(executive_type, '')) as executive_type,
            trim(coalesce(officer_type, '')) as officer_type,
            trim(coalesce(highly_compensated_type, '')) as highly_compensated_type,
            trim(coalesce(work_shift, '')) as work_shift,
            trim(coalesce(work_arrangement, '')) as work_arrangement,
            trim(coalesce(remuneration_basis, '')) as remuneration_basis,
            trim(
                coalesce(geographic_pay_differential, '')
            ) as geographic_pay_differential,
            trim(coalesce(job_function, '')) as job_function,
            trim(coalesce(payroll_processing_status, '')) as payroll_processing_status,
            trim(coalesce(pay_scale, '')) as pay_scale,
            trim(coalesce(pay_grade, '')) as pay_grade,
            trim(coalesce(pay_grade_step, '')) as pay_grade_step,
            trim(coalesce(job, '')) as job,
            trim(coalesce(pay_cycle, '')) as pay_cycle,
            trim(coalesce(WAGE_LAW_COVERAGE_NAME_SHORT_NAME, '')) as WAGE_LAW_COVERAGE_NAME_SHORT_NAME,
            trim(coalesce(WAGE_LAW_COVERAGE_NAME_LONG_NAME, '')) as WAGE_LAW_COVERAGE_NAME_LONG_NAME,
            trim(coalesce(WAGE_LAW_COVERAGE_NAME_SUBDIVISION_TYPE, '')) as WAGE_LAW_COVERAGE_NAME_SUBDIVISION_TYPE,
            cast(WAGE_LAW_COVERAGE_NAME_EFFECTIVE_DATE as DATE) as WAGE_LAW_COVERAGE_NAME_EFFECTIVE_DATE,
            trim(coalesce(WAGE_LAW_COVERAGE_SHORT_NAME, '')) as WAGE_LAW_COVERAGE_SHORT_NAME,
            trim(coalesce(WAGE_LAW_COVERAGE_LONG_NAME, '')) as WAGE_LAW_COVERAGE_LONG_NAME,
            trim(coalesce(WAGE_LAW_COVERAGE_SUBDIVISION_TYPE, '')) as WAGE_LAW_COVERAGE_SUBDIVISION_TYPE,
            cast(WAGE_LAW_COVERAGE_EFFECTIVE_DATE as DATE) as WAGE_LAW_COVERAGE_EFFECTIVE_DATE,
            trim(coalesce(WAGE_LAW_COVERAGE_NAME, '')) as WAGE_LAW_COVERAGE_NAME,
            cast(_fivetran_synced as timestamp_tz) as _fivetran_synced,
            cast(_fivetran_start as timestamp_tz) as _fivetran_start,
            cast(_fivetran_end as timestamp_tz) as _fivetran_end,
            coalesce(_fivetran_active, false) as _fivetran_active,
            current_timestamp() as silver_load_date
        from source_data

    )

select *
from cleaned
