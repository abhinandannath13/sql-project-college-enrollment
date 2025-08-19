-- Temp table: Get last year’s enrolled students
with prev_year_students as (
    select o.student_id, c.course_title, o.paymentstatus
    from campus_data.fact_orders o 
    inner join campus_academics.courses c on o.course_id = c.course_id
    where o.paymentstatus != 'failed'
      and c.program_type = 'full_course'
      and c.org_code not in ('college-demo','campus-test','hybrid-temp','dummy-account')
      and c.course_title not like '%Demo%'
      and c.course_title not like '%2023-24%'
      and lower(c.course_title) not like '%dummy%'
      and (
           
            lower(c.course_title) like '%2024-2025%' or
            lower(c.course_title) like '%24-25%'
            
      )
      or o.student_id in ('s_1001','s_1002','s_1003','s_1004')
),

-- Current year enrollments
enrollment_raw as (
    select distinct 
        o.order_id,
        convert_timezone('Asia/Kolkata', timestamp 'epoch' + (o.created_at/1000) * interval '1 second')::date as order_date,
        o.student_id,
        o.paymentstatus,
        u.full_name,
        u.student_rollno,
        c.course_title,
        o.amount  as course_value,
        o.amount_paid as order_value,
        case 
            when c.course_title ilike '%engineering%' then 'Engineering'
            when c.course_title ilike '%medical%' then 'Medical'
            else 'General'
        end as stream,
        coalesce(gf.grade_value::text, o.grade::text) as course_grade,
        c.city,
        c.college_name,
        b.batch_id,
        convert_timezone('Asia/Kolkata', timestamp 'epoch' + (b.start_time/1000) * interval '1 second')::date as batch_start_date,
        b.subjects as batch_subjects,
        b.batch_name,
        case when e.student_alias is not null then 'Yes' end as kit_distributed,
        o.delivery_id,
        p.payment_type,
        case 
            when c.program_type ilike '%SCHOLERSHIP%' then 'Scholership'
            else 'Regular'
        end as business_unit
    from campus_data.fact_orders o
    inner join campus_academics.courses c on c.course_id = o.course_id
    left join campus_users.students u on u.student_id = o.student_id
    left join campus_academics.batches b on b.batch_id = o.batch_id
    left join campus_data.grade_fact gf on gf.ref_id = b.course_id
    left join (select * from campus_academics.enrollments where status = 'ACTIVE') e on e.enrollment_id = o.order_id
    left join (
        select ref_id, max(convert_timezone('Asia/Kolkata', timestamp 'epoch' + (changed_time/1000) * interval '1 second')) as changed_time
        from campus_data.order_status_changes
        where new_status = 'failed'

        group by 1
    ) f on f.ref_id = o.order_id
    left join campus_data.payment_details p on p.order_id = o.order_id
    where c.delivery_mode = 'OFFLINE'
      and o.paymentstatus !=  ’chrun’

      and c.program_type = 'full_course'
      and c.org_code not in ('college-demo','campus-test','hybrid-temp','dummy-account')
      and c.course_title not like '%Demo%'
      and lower(c.course_title) like '%2025-2026%'
      ),


-- KYC + verification
kyc_verification as (
    select distinct 
        e.order_id,
        e.student_id,
        case when k.timestamp is not null then 'Yes' else 'No' end as kyc_status,
        case when v.timestamp is not null then 'Yes' else 'No' end as verification_status,
        i.roll_no,
        i.kit_status,
        i.id_card,
        max(to_timestamp(k.timestamp, 'MM/DD/YYYY HH24:MI:SS'))::date as kyc_done_date,
        cast(max(to_timestamp(v.timestamp, 'MM/DD/YYYY HH24:MI:SS')) as date) as verification_done_date
    from enrollment_raw
    left join campus_reporting.kyc k on k.order_id = e.order_id
    left join campus_reporting.verification v on v.order_id = e.order_id
    left join campus_reporting.inventory i on i.student_id = e.student_id
    group by 1,2,3,4,5,6,7
),

-- Active enrollments
active_enrolled as (
    select *, row_number() over (partition by student_id order by order_date desc)::int as order_num
    from enrollment_raw
    where paymentstatus in (‘paid’,'instalment',’drop’)
),

-- Forfeited students (churn check)
forfeited as (
    select *, row_number() over (partition by student_id order by order_date desc)::int as order_num
    from enrollment_raw
    where      paymentstatus =’chrun’
      and student_id not in (select student_id from active_enrolled)
),

-- Merge both
final_enrollment as (
    select * from active_enrolled
    union all 
    select * from forfeited where order_num = 1
)

-- Insert into reporting table
delete from campus_reporting.new_student_enrollment;
insert into campus_reporting.new_student_enrollment;
select * from final_enrollment
order by order_date;


