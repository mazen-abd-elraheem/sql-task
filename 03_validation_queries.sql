-- ============================================================================
-- 02. DATA VALIDATION & INTEGRITY QUERIES
-- ============================================================================
USE HealthcareAnalyticsDB;
GO

-- 1. Check Row Counts Across Staging & Normalized Tables
SELECT 'stg_raw_visits' AS TableName, COUNT(*) AS TotalRows FROM dbo.stg_raw_visits
UNION ALL
SELECT 'patients', COUNT(*) FROM dbo.patients
UNION ALL
SELECT 'medical_services', COUNT(*) FROM dbo.medical_services
UNION ALL
SELECT 'visits', COUNT(*) FROM dbo.visits
UNION ALL
SELECT 'billing_items', COUNT(*) FROM dbo.billing_items;

-- 2. Preview Top 100 Rows Joined Across All Tables
SELECT TOP 100
    v.visit_id,
    v.visit_date,
    v.visit_type,
    p.patient_id,
    p.insurance_type,
    p.branch,
    m.department,
    m.procedure_name,
    b.net_revenue,
    b.net_profit,
    b.is_readmitted,
    b.satisfaction_score
FROM dbo.billing_items b
JOIN dbo.visits v ON b.visit_id = v.visit_id
JOIN dbo.patients p ON v.patient_id = p.patient_id
JOIN dbo.medical_services m ON b.service_key = m.service_key
ORDER BY v.visit_date DESC;

-- 3. Financial Reconciliation Check
SELECT 
    (SELECT SUM(net_revenue) FROM dbo.stg_raw_visits) AS Staging_Net_Revenue,
    (SELECT SUM(net_revenue) FROM dbo.billing_items) AS Normalized_Net_Revenue,
    (SELECT SUM(net_profit) FROM dbo.stg_raw_visits) AS Staging_Net_Profit,
    (SELECT SUM(net_profit) FROM dbo.billing_items) AS Normalized_Net_Profit;
