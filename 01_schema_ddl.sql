-- ============================================================================
-- 01. DATABASE SCHEMA & DDL (SQL Server / T-SQL) — Healthcare Analytics
-- Normalized Relational Design (3NF Structure)
-- ============================================================================

CREATE DATABASE HealthcareAnalyticsDB;
GO

USE HealthcareAnalyticsDB;
GO

-- 1. Staging Table for Raw CSV Import
CREATE TABLE dbo.stg_raw_visits (
    visit_id           VARCHAR(20),
    visit_date         DATE,
    visit_type         VARCHAR(30),
    wait_minutes       INT,
    stay_days          INT,
    patient_id         VARCHAR(20),
    insurance_type     VARCHAR(40),
    branch             VARCHAR(40),
    department         VARCHAR(50),
    procedure_name     VARCHAR(60),
    doctor_tier        VARCHAR(30),
    base_fee           DECIMAL(12, 2),
    lab_imaging_fee    DECIMAL(12, 2),
    discount_rate      DECIMAL(5, 2),
    gross_bill         DECIMAL(14, 2),
    net_revenue        DECIMAL(14, 2),
    medical_cost       DECIMAL(14, 2),
    net_profit         DECIMAL(14, 2),
    is_readmitted      BIT,
    satisfaction_score INT
);
GO

-- Bulk Insert Command (Switch between 30-row test CSV or 12,500-row full CSV)
/*
BULK INSERT dbo.stg_raw_visits
FROM 'C:\Data\healthcare_visits_full_12500rows.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO
*/

-- 2. Normalized Dimension & Fact Tables
CREATE TABLE dbo.patients (
    patient_id     VARCHAR(20) PRIMARY KEY,
    insurance_type VARCHAR(40) NOT NULL,
    branch         VARCHAR(40) NOT NULL
);

CREATE TABLE dbo.medical_services (
    service_key    INT IDENTITY(1,1) PRIMARY KEY,
    department     VARCHAR(50) NOT NULL,
    procedure_name VARCHAR(60) NOT NULL,
    CONSTRAINT UQ_Dept_Procedure UNIQUE (department, procedure_name)
);

CREATE TABLE dbo.visits (
    visit_id     VARCHAR(20) PRIMARY KEY,
    visit_date   DATE NOT NULL,
    visit_type   VARCHAR(30) NOT NULL,
    wait_minutes INT NOT NULL CHECK (wait_minutes >= 0),
    stay_days    INT NOT NULL CHECK (stay_days >= 0),
    doctor_tier  VARCHAR(30) NOT NULL,
    patient_id   VARCHAR(20) NOT NULL,
    CONSTRAINT FK_Visits_Patients FOREIGN KEY (patient_id) REFERENCES dbo.patients(patient_id)
);

CREATE TABLE dbo.billing_items (
    billing_id         INT IDENTITY(1,1) PRIMARY KEY,
    visit_id           VARCHAR(20) NOT NULL,
    service_key        INT NOT NULL,
    base_fee           DECIMAL(12, 2) NOT NULL CHECK (base_fee > 0),
    lab_imaging_fee    DECIMAL(12, 2) NOT NULL CHECK (lab_imaging_fee >= 0),
    discount_rate      DECIMAL(5, 2) NOT NULL CHECK (discount_rate BETWEEN 0 AND 1),
    gross_bill         DECIMAL(14, 2) NOT NULL,
    net_revenue        DECIMAL(14, 2) NOT NULL,
    medical_cost       DECIMAL(14, 2) NOT NULL,
    net_profit         DECIMAL(14, 2) NOT NULL,
    is_readmitted      BIT NOT NULL DEFAULT 0,
    satisfaction_score INT CHECK (satisfaction_score BETWEEN 1 AND 5),
    CONSTRAINT FK_Billing_Visits FOREIGN KEY (visit_id) REFERENCES dbo.visits(visit_id),
    CONSTRAINT FK_Billing_Services FOREIGN KEY (service_key) REFERENCES dbo.medical_services(service_key)
);
GO

-- 3. Populate Normalized Tables from Staging Table
INSERT INTO dbo.patients (patient_id, insurance_type, branch)
SELECT patient_id, MAX(insurance_type), MAX(branch)
FROM dbo.stg_raw_visits
GROUP BY patient_id;

INSERT INTO dbo.medical_services (department, procedure_name)
SELECT DISTINCT department, procedure_name
FROM dbo.stg_raw_visits;

INSERT INTO dbo.visits (visit_id, visit_date, visit_type, wait_minutes, stay_days, doctor_tier, patient_id)
SELECT DISTINCT visit_id, visit_date, visit_type, wait_minutes, stay_days, doctor_tier, patient_id
FROM dbo.stg_raw_visits;

INSERT INTO dbo.billing_items (
    visit_id, service_key, base_fee, lab_imaging_fee, discount_rate,
    gross_bill, net_revenue, medical_cost, net_profit, is_readmitted, satisfaction_score
)
SELECT 
    s.visit_id, m.service_key, s.base_fee, s.lab_imaging_fee, s.discount_rate,
    s.gross_bill, s.net_revenue, s.medical_cost, s.net_profit, s.is_readmitted, s.satisfaction_score
FROM dbo.stg_raw_visits s
JOIN dbo.medical_services m 
    ON s.department = m.department AND s.procedure_name = m.procedure_name;
GO
