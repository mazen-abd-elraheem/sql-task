# Healthcare Operations & Billing SQL Analytics Project

## Overview
End-to-end relational database normalization (3NF) and business intelligence analysis built on **Microsoft SQL Server (T-SQL)** using a Healthcare & Hospital Operations dataset.

## Included Files
- `healthcare_visits_full_12500rows.csv`: Full dataset (12,500 rows, 20 features) for final submission.
- `healthcare_visits_test_30rows.csv`: 30-row balanced sample dataset for quick local testing.
- `01_schema_ddl.sql`: Database schema, staging table, normalized 3NF tables (`patients`, `medical_services`, `visits`, `billing_items`), and ETL population scripts.
- `02_validation_queries.sql`: Row count verification, joined preview, and financial parity checks.
- `03_business_insights.sql`: 10 executive SQL queries (JOINs, GROUP BY, HAVING, CTEs, DENSE_RANK, LAG).
- `ERD_and_Mapping_Diagram.png`: Visual ERD and schema mapping diagram.
- `Project_Documentation.docx`: Full documentation report ready for SSMS screenshots.
