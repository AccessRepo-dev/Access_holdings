{% set company = var("company", "amh") %}
{% set sourcesystem = var("sourcesystem", "paycom") %}


{{
    config(
        enabled=(var("sourcesystem", "paycom") | lower) in ["paycom"]
        and (var("company", "amh") | lower) in ["amh"],
        database=get_target_database(company),
        alias=sourcesystem ~ "_EMPLOYEES",
        schema="silver",
        unique_key="eecode",
        materialized="incremental",
        incremental_strategy="merge",
        on_schema_change="sync_all_columns",
    )
}}


with
    raw as (
        select *
        from {{ get_raw_source(company, sourcesystem, "EMPLOYEES") }}

        {% if is_incremental() %}
            where
                cast(_loaded_at as timestamp_ntz) > (
                    select
                        dateadd(
                            day,
                            -1,
                            coalesce(max(_loaded_at), '1900-01-01'::timestamp_ntz)
                        )
                    from {{ this }}
                )
        {% endif %}

    ),
    cleaned as (
        select

            -- TEXT (trim)
            trim(eecode) as eecode,
            trim(employee_code) as employee_code,
            trim(employee_status) as employee_status,
            cast(trim(hire_date) as date) as hire_date,
            cast(trim(seniority_date) as date) as seniority_date,
            cast(trim(employee_added) as date) as employee_added,
            cast(trim(termination_date) as date) as termination_date,
            trim(termination_reason) as termination_reason,
            trim(termination_type) as termination_type,
            cast(trim(previous_termination_date) as date) as previous_termination_date,
            cast(trim(rehire_date) as date) as rehire_date,

            -- BOOLEAN
            cast(new_hire as boolean) as new_hire,

            -- TEXT
            trim(business_title) as business_title,
            trim(department_code) as department_code,
            trim(department_description) as department_description,
            trim(pay_class) as pay_class,
            trim(pay_frequency) as pay_frequency,

            -- BOOLEAN
            cast(hourly_or_salary as boolean) as hourly_or_salary,

            -- NUMBER
            cast(fulltime_or_parttime as number) as fulltime_or_parttime,

            -- TEXT
            trim(dol_status) as dol_status,
            trim(exempt_status) as exempt_status,
            cast(custom_standard_hours as float) as custom_standard_hours,

            -- BOOLEAN
            cast(comission_only as boolean) as comission_only,

            -- DATE
            cast(trim(last_pay_change) as date) as last_pay_change,
            cast(trim(most_recent_check_date) as date) as most_recent_check_date,

            -- TEXT
            trim(position) as position,
            trim(position_code) as position_code,
            trim(position_family) as position_family,
            trim(position_family_code) as position_family_code,
            trim(position_family_name) as position_family_name,
            trim(position_id) as position_id,
            trim(position_level) as position_level,
            trim(position_seat_number) as position_seat_number,
            trim(position_seat_title) as position_seat_title,
            trim(position_title) as position_title,

            -- DATE
            cast(trim(last_position_change_date) as date) as last_position_change_date,

            -- TEXT
            trim(manager_level) as manager_level,
            trim(employee_supervisor_level) as employee_supervisor_level,
            trim(supervisor_primary) as supervisor_primary,
            trim(supervisor_primary_code) as supervisor_primary_code,
            trim(supervisor_secondary) as supervisor_secondary,
            trim(supervisor_secondary_code) as supervisor_secondary_code,
            trim(supervisor_tertiary) as supervisor_tertiary,
            trim(supervisor_tertiary_code) as supervisor_tertiary_code,
            trim(supervisor_quaternary) as supervisor_quaternary,
            trim(supervisor_quaternary_code) as supervisor_quaternary_code,
            trim(supervisor_approval) as supervisor_approval,
            trim(supervisor_approval_code) as supervisor_approval_code,
            trim(location) as location,

            -- FLOAT
            cast(companyestablishmentid as float) as companyestablishmentid,
            cast(companylocationid as float) as companylocationid,

            -- TEXT
            trim(labor_allocation_profile) as labor_allocation_profile,
            trim(labor_allocation_details) as labor_allocation_details,

            -- DATE
            cast(trim(leave_start) as date) as leave_start,
            cast(trim(leave_end) as date) as leave_end,

            -- NUMBER
            cast(schedule_group as number) as schedule_group,

            -- BOOLEAN
            cast(available_health_insurance as boolean) as available_health_insurance,
            cast(retirement_plan as boolean) as retirement_plan,

            -- TEXT
            trim(eligible_401k) as eligible_401k,
            trim(hours_401k) as hours_401k,

            -- DATE
            cast(trim(last_review) as date) as last_review,
            cast(trim(next_review) as date) as next_review,

            -- TEXT
            trim(length_of_service_since_hire) as length_of_service_since_hire,
            trim(length_of_service_since_rehire) as length_of_service_since_rehire,
            trim(employee_badge) as employee_badge,
            trim(employee_gl_code) as employee_gl_code,

            -- BOOLEAN
            cast(has_direct_deposit as boolean) as has_direct_deposit,

            -- TEXT
            trim(eeoc_class) as eeoc_class,
            trim(eeoc_class_description) as eeoc_class_description,
            trim(workers_comp_code) as workers_comp_code,
            trim(workers_comp_desc) as workers_comp_desc,

            -- TIMESTAMP_TZ
            trim(_etl_batch_id) as _etl_batch_id,
            cast(_deleted_at as timestamp_tz) as _deleted_at,
            current_timestamp()::timestamp_ntz as silver_load_date,
            _loaded_at::timestamp_ntz as raw_load_date

        from raw
    )

select *
from cleaned
