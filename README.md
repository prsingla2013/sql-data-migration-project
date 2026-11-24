# Legacy CRM to Modern CRM Data Migration (SQL Server)

## Problem
A legacy CRM database (LegacyCRM) had messy customer and order data that needed to move into a clean new system (ModernCRM). Issues included exact duplicate customers, the same customer entered under two numbers, missing names, phone numbers and ZIP codes in mixed formats, dates stored as text in several formats, amounts with "$" and commas, inconsistent order status values (Shipped, shipped, CNCL, Cancelled), and orders pointing to customers that don't exist.

## Approach
I followed the same steps I use for real data conversions:
1. Staging: copy the source data into a stg schema so the source is never changed.
2. Cleansing: remove exact duplicates with ROW_NUMBER, merge duplicate customers using a merge map, standardize phone, ZIP, email and dates with TRY_CONVERT, clean amounts, and map status values.
3. Error logging: every rejected row or fixed value is written to an error log table with the source table, column, level (ERROR or WARNING) and reason.
4. Loading: insert only valid rows into the target tables, linking orders to the new CustomerID.
5. Validation and reconciliation: compare source vs. target counts and totals and run data quality checks.

## Scripts (run in order in SSMS)
| Script | Purpose |
|---|---|
| 01_create_databases.sql | Create LegacyCRM and ModernCRM |
| 02_create_legacy_tables.sql | Create legacy source tables |
| 03_load_legacy_data.sql | Generate synthetic messy test data |
| 04_create_target_tables.sql | Create clean target tables and error log |
| 05_load_staging.sql | Copy source data into staging |
| 06_cleanse_customers.sql | Deduplicate and clean customers |
| 07_cleanse_orders.sql | Match customers, clean dates, amounts and status |
| 08_load_customers.sql | Load clean customers and reconcile |
| 09_load_orders.sql | Load clean orders and reconcile |
| 10_validation.sql | Final data quality checks and error summary |

## Results
- Customers: 1,030 source rows, 997 loaded, 20 exact duplicates removed, 10 merged, 3 rejected (missing name)
- Orders: 3,000 source rows, 2,966 loaded, 34 rejected (29 with no matching customer, 5 with an invalid date)
- All 7 validation checks returned 0 issues: no orphan orders, no duplicate keys, no bad phone or ZIP formats, no negative amounts, and order totals match between source and target.

## Note
All data is synthetic and created by 03_load_legacy_data.sql. No real customer data is used.

## Related experience
This project reflects the conversion work I have done professionally: client data conversions at MemberClicks, data conversion engineering at Improveit360 / EverCommerce, and healthcare data migration as a Senior Database Analyst at the State of Indiana (FSSA/DMHA).

## Tools
SQL Server 2025, SSMS, T-SQL