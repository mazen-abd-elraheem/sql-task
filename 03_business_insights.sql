-- ============================================================================
-- 03. BUSINESS INSIGHTS QUERIES (10 Executive Analytical Queries)
-- Covers: JOINs, Aggregations, GROUP BY, HAVING, CTEs, Window Functions, CASE
-- ============================================================================
USE HealthcareAnalyticsDB;
GO

-- INSIGHT 1: Revenue, Net Profit & Profit Margin by Medical Department
SELECT 
    m.department,
    COUNT(b.billing_id) AS total_visits,
    SUM(b.net_revenue) AS total_revenue,
    SUM(b.net_profit) AS total_profit,
    CAST(ROUND((SUM(b.net_profit) / NULLIF(SUM(b.net_revenue), 0)) * 100, 2) AS DECIMAL(5,2)) AS profit_margin_pct
FROM dbo.billing_items b
JOIN dbo.medical_services m ON b.service_key = m.service_key
GROUP BY m.department
ORDER BY total_profit DESC;

-- INSIGHT 2: Impact of Insurance Discount Tiers on Margin & Readmission Rates
SELECT 
    CASE 
        WHEN b.discount_rate = 0 THEN '0% (Self-Pay / No Discount)'
        WHEN b.discount_rate <= 0.20 THEN '10% - 20% (Standard Plan)'
        ELSE '30% - 50% (Heavy Coverage)'
    END AS coverage_tier,
    COUNT(*) AS visit_count,
    AVG(b.net_revenue) AS avg_net_bill,
    SUM(b.net_profit) AS total_profit,
    CAST(ROUND((SUM(b.net_profit) / NULLIF(SUM(b.net_revenue), 0)) * 100, 2) AS DECIMAL(5,2)) AS margin_pct,
    CAST(ROUND(AVG(CAST(b.is_readmitted AS FLOAT)) * 100, 2) AS DECIMAL(5,2)) AS readmission_rate_pct
FROM dbo.billing_items b
GROUP BY 
    CASE 
        WHEN b.discount_rate = 0 THEN '0% (Self-Pay / No Discount)'
        WHEN b.discount_rate <= 0.20 THEN '10% - 20% (Standard Plan)'
        ELSE '30% - 50% (Heavy Coverage)'
    END
ORDER BY margin_pct DESC;

-- INSIGHT 3: Hospital Branch Performance, Wait Times & Patient Satisfaction
SELECT 
    p.branch,
    COUNT(DISTINCT v.visit_id) AS total_visits,
    COUNT(DISTINCT p.patient_id) AS unique_patients,
    SUM(b.net_revenue) AS total_revenue,
    SUM(b.net_profit) AS total_profit,
    CAST(AVG(CAST(v.wait_minutes AS FLOAT)) AS DECIMAL(5,2)) AS avg_wait_mins,
    CAST(AVG(CAST(b.satisfaction_score AS FLOAT)) AS DECIMAL(3,2)) AS avg_satisfaction
FROM dbo.visits v
JOIN dbo.patients p ON v.patient_id = p.patient_id
JOIN dbo.billing_items b ON v.visit_id = b.visit_id
GROUP BY p.branch
ORDER BY total_revenue DESC;

-- INSIGHT 4: Top 2 Procedures per Department Ranked by Net Profit (Window Function)
WITH ProcedureProfit AS (
    SELECT 
        m.department,
        m.procedure_name,
        SUM(b.net_revenue) AS revenue,
        SUM(b.net_profit) AS profit,
        DENSE_RANK() OVER (PARTITION BY m.department ORDER BY SUM(b.net_profit) DESC) AS rnk
    FROM dbo.billing_items b
    JOIN dbo.medical_services m ON b.service_key = m.service_key
    GROUP BY m.department, m.procedure_name
)
SELECT department, procedure_name, revenue, profit, rnk
FROM ProcedureProfit
WHERE rnk <= 2
ORDER BY department, rnk;

-- INSIGHT 5: Monthly Revenue Trend & Month-over-Month (MoM) Growth %
WITH MonthlyRevenue AS (
    SELECT 
        FORMAT(v.visit_date, 'yyyy-MM') AS visit_month,
        SUM(b.net_revenue) AS monthly_revenue,
        SUM(b.net_profit) AS monthly_profit
    FROM dbo.visits v
    JOIN dbo.billing_items b ON v.visit_id = b.visit_id
    GROUP BY FORMAT(v.visit_date, 'yyyy-MM')
)
SELECT 
    visit_month,
    monthly_revenue,
    monthly_profit,
    LAG(monthly_revenue) OVER (ORDER BY visit_month) AS prev_month_revenue,
    CAST(ROUND(
        ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY visit_month)) 
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY visit_month), 0)) * 100, 2
    ) AS DECIMAL(6,2)) AS mom_growth_pct
FROM MonthlyRevenue
ORDER BY visit_month;

-- INSIGHT 6: Frequent / High-Billing Patients (HAVING Filter > 10,000 EGP)
SELECT 
    p.patient_id,
    p.insurance_type,
    p.branch,
    COUNT(DISTINCT v.visit_id) AS visits_count,
    SUM(b.net_revenue) AS total_billed,
    SUM(b.net_profit) AS total_profit,
    CAST(AVG(CAST(b.satisfaction_score AS FLOAT)) AS DECIMAL(3,2)) AS avg_score
FROM dbo.patients p
JOIN dbo.visits v ON p.patient_id = v.patient_id
JOIN dbo.billing_items b ON v.visit_id = b.visit_id
GROUP BY p.patient_id, p.insurance_type, p.branch
HAVING SUM(b.net_revenue) > 10000
ORDER BY total_billed DESC;

-- INSIGHT 7: Doctor Tier Efficiency vs. Patient Satisfaction & Readmission
SELECT 
    v.doctor_tier,
    COUNT(DISTINCT v.visit_id) AS total_visits,
    CAST(AVG(CAST(v.wait_minutes AS FLOAT)) AS DECIMAL(5,2)) AS avg_wait_mins,
    CAST(AVG(CAST(b.satisfaction_score AS FLOAT)) AS DECIMAL(3,2)) AS avg_satisfaction,
    CAST(ROUND(AVG(CAST(b.is_readmitted AS FLOAT)) * 100, 2) AS DECIMAL(5,2)) AS readmission_pct
FROM dbo.visits v
JOIN dbo.billing_items b ON v.visit_id = b.visit_id
GROUP BY v.doctor_tier
ORDER BY avg_satisfaction DESC;

-- INSIGHT 8: Insurance Type Revenue & Average Visit Value by Visit Type
SELECT 
    v.visit_type,
    p.insurance_type,
    COUNT(DISTINCT v.visit_id) AS total_visits,
    CAST(AVG(b.net_revenue) AS DECIMAL(10,2)) AS avg_visit_revenue,
    SUM(b.net_revenue) AS total_revenue
FROM dbo.visits v
JOIN dbo.patients p ON v.patient_id = p.patient_id
JOIN dbo.billing_items b ON v.visit_id = b.visit_id
GROUP BY v.visit_type, p.insurance_type
ORDER BY v.visit_type, total_revenue DESC;

-- INSIGHT 9: Negative Margin Visits Root Cause Analysis (Loss-Making Cases)
SELECT 
    m.department,
    COUNT(*) AS loss_making_visits,
    CAST(AVG(b.discount_rate) * 100 AS DECIMAL(5,2)) AS avg_discount_pct,
    SUM(b.net_profit) AS total_loss_amount
FROM dbo.billing_items b
JOIN dbo.medical_services m ON b.service_key = m.service_key
WHERE b.net_profit < 0
GROUP BY m.department
ORDER BY total_loss_amount ASC;

-- INSIGHT 10: Patient Retention Cohort (One-Time vs. Repeat Patients)
WITH PatientVisitCounts AS (
    SELECT 
        patient_id,
        COUNT(DISTINCT visit_id) AS visit_count,
        SUM(b.net_revenue) AS total_spent
    FROM dbo.visits v
    JOIN dbo.billing_items b ON v.visit_id = b.visit_id
    GROUP BY patient_id
)
SELECT 
    CASE 
        WHEN visit_count = 1 THEN 'One-Time Patient'
        WHEN visit_count BETWEEN 2 AND 4 THEN 'Repeat Patient (2-4)'
        ELSE 'Regular Patient (5+)'
    END AS patient_group,
    COUNT(patient_id) AS patient_count,
    SUM(total_spent) AS group_revenue,
    CAST(AVG(total_spent) AS DECIMAL(10,2)) AS avg_ltv
FROM PatientVisitCounts
GROUP BY 
    CASE 
        WHEN visit_count = 1 THEN 'One-Time Patient'
        WHEN visit_count BETWEEN 2 AND 4 THEN 'Repeat Patient (2-4)'
        ELSE 'Regular Patient (5+)'
    END
ORDER BY group_revenue DESC;
