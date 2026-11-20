USE HealthcareAnalyticsDB;
GO

BULK INSERT dbo.stg_raw_visits
FROM 'C:\Data\healthcare_data.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

SELECT COUNT(*) FROM dbo.stg_raw_visits;   -- should return 12500