**College Analytics Insights**

This project provides an SQL-based data pipeline that tracks and reports student enrollments, churns, verifications, and KYC status across academic years. The goal is to help stakeholders (college admins, operations, and management) monitor new student enrollments, identify churned/forfeited students, and ensure smooth onboarding processes.

**Business Context-**

**Colleges often struggle to track:**

    How many students continued from the previous year.

    How many new students joined in the current year.

    Which students churned (didn’t complete payment/enrollment).

    Whether students completed KYC, verification, and kit distribution.

This query consolidates data across multiple campus systems (orders, courses, batches, KYC, verification, and payments) to create a single reporting table for student enrollment insights.

 **Query Breakdown-**

1. Previous Year Students (prev_year_students)

    Pulls last year’s enrolled students.

    Excludes test/dummy/demo courses.

    Adds exceptions for manually included student IDs.

2. Current Year Enrollments (enrollment_raw)

    Captures student orders with course, batch, payment, and stream classification.

    Adds business unit flag (Scholarship vs Regular).

    Cleans out failed/demo enrollments.

    Restricts to current academic year (2025–26).

3. KYC & Verification (kyc_verification)

    Tracks KYC completion and verification dates.

    Adds kit status and ID card distribution.

4. Active Enrollments (active_enrolled)

    Keeps only the latest order per student.

    Includes statuses: paid, instalment, drop.

5. Forfeited Students (forfeited)

    Identifies students with status = churn.

    Ensures only their latest record is retained.

6. Final Enrollment (final_enrollment)

    Combines active enrollments + forfeited students.

7. Insert into Reporting Table

    Deletes old data from campus_reporting.new_student_enrollment.

    Inserts fresh data with a clean order-by-date view.

**Key Outcomes**

Clean reporting table with new student enrollments.

Tracks KYC & verification status for compliance.

Identifies churned/forfeited students clearly.

Provides business-ready insights for college dashboards.

Run as a scheduled job (daily/weekly).

Connect the output table (campus_reporting.new_student_enrollment) to BI tools like Tableau, Power BI, or Looker Studio for dashboards.

**Future Enhancements**

  Add multi-year trend tracking (YOY comparisons).

  Integrate attendance data for deeper engagement insights.

  Build alerts for students at risk of churn (early warning system).
