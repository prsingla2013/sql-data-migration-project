USE ModernCRM;
GO
ALTER TABLE stg.ORDER_HDR ADD CustomerID INT NULL;
GO
UPDATE o
SET o.CustomerID = c.CustomerID
FROM stg.ORDER_HDR o
JOIN dbo.Customer c ON c.LegacyCustNo = LTRIM(RTRIM(o.CUST_NO));
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'ORDER_HDR', ORD_NO, 'CUST_NO', CUST_NO, 'ERROR',
       'Customer not found in target (orphan or rejected customer)'
FROM stg.ORDER_HDR
WHERE CustomerID IS NULL;
SELECT COUNT(*) AS TotalOrders,
       COUNT(CustomerID) AS Matched,
       SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Unmatched,
       SUM(CASE WHEN CUST_NO = 'C99999' THEN 1 ELSE 0 END) AS OrphanC99999
FROM stg.ORDER_HDR;

--Step 2: clean the order date
ALTER TABLE stg.ORDER_HDR ADD CleanOrderDate DATE NULL;
GO
UPDATE stg.ORDER_HDR
SET CleanOrderDate = COALESCE(
        TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(ORD_DT)), ''), 23),
        TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(ORD_DT)), ''), 101),
        TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(ORD_DT)), ''), 107));
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'ORDER_HDR', ORD_NO, 'ORD_DT', ORD_DT, 'ERROR', 'Missing or invalid order date'
FROM stg.ORDER_HDR
WHERE CleanOrderDate IS NULL;
SELECT COUNT(*) AS TotalOrders,
       COUNT(CleanOrderDate) AS ValidDates,
       SUM(CASE WHEN CleanOrderDate IS NULL THEN 1 ELSE 0 END) AS BadDates,
       MIN(CleanOrderDate) AS EarliestDate,
       MAX(CleanOrderDate) AS LatestDate
FROM stg.ORDER_HDR;

--Step 3: clean the order amount.
ALTER TABLE stg.ORDER_HDR ADD CleanAmount DECIMAL(10,2) NULL;
GO
UPDATE stg.ORDER_HDR
SET CleanAmount = TRY_CONVERT(DECIMAL(10,2),
        REPLACE(REPLACE(LTRIM(RTRIM(ORD_AMT)), '$', ''), ',', ''));
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'ORDER_HDR', ORD_NO, 'ORD_AMT', ORD_AMT, 'ERROR',
       CASE WHEN CleanAmount IS NULL THEN 'Non-numeric order amount'
            ELSE 'Negative order amount' END
FROM stg.ORDER_HDR
WHERE CleanAmount IS NULL OR CleanAmount < 0;
SELECT COUNT(*) AS TotalOrders,
       SUM(CASE WHEN CleanAmount IS NULL THEN 1 ELSE 0 END) AS NonNumeric,
       SUM(CASE WHEN CleanAmount < 0 THEN 1 ELSE 0 END) AS Negative,
       MIN(CleanAmount) AS MinAmt,
       MAX(CleanAmount) AS MaxAmt
FROM stg.ORDER_HDR;

--Step 4: standardize the order status

ALTER TABLE stg.ORDER_HDR ADD CleanStatus VARCHAR(20) NULL;
GO
UPDATE stg.ORDER_HDR
SET CleanStatus = CASE UPPER(LTRIM(RTRIM(ORD_STATUS)))
                    WHEN 'SHIPPED'   THEN 'SHIPPED'
                    WHEN 'CANCELLED' THEN 'CANCELLED'
                    WHEN 'CNCL'      THEN 'CANCELLED'
                    WHEN 'OPEN'      THEN 'OPEN'
                  END;
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'ORDER_HDR', ORD_NO, 'ORD_STATUS', ORD_STATUS, 'ERROR', 'Unknown order status'
FROM stg.ORDER_HDR
WHERE CleanStatus IS NULL;
SELECT ORD_STATUS, CleanStatus, COUNT(*) AS Cnt
FROM stg.ORDER_HDR
GROUP BY ORD_STATUS, CleanStatus
ORDER BY CleanStatus, ORD_STATUS;

