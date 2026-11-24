USE ModernCRM;
GO
--TRUNCATE TABLE ModernCRM.dbo.MigrationErrorLog;
-- Step 1: remove exact duplicate rows (keep the first copy)
;WITH d AS (
    SELECT StgRowID,
           ROW_NUMBER() OVER (
               PARTITION BY CUST_NO, CUST_NAME, EMAIL, PHONE, ADDR_LINE,
                            CITY, ST, ZIP, JOIN_DT, STATUS_CD
               ORDER BY StgRowID) AS rn
    FROM stg.CUST_MASTER
)
DELETE FROM d WHERE rn > 1;
SELECT @@ROWCOUNT AS ExactDuplicatesRemoved;
SELECT COUNT(*) AS RowsLeft FROM stg.CUST_MASTER;

-- Step 2: merge customers re-entered under C9xxxx numbers
IF OBJECT_ID('stg.CustomerMergeMap', 'U') IS NOT NULL DROP TABLE stg.CustomerMergeMap;
SELECT d.CUST_NO AS DuplicateCustNo,
       o.CUST_NO AS OriginalCustNo
INTO stg.CustomerMergeMap
FROM stg.CUST_MASTER d
JOIN stg.CUST_MASTER o
  ON o.CUST_NO = 'C0' + RIGHT(d.CUST_NO, 4)
 AND ISNULL(o.CUST_NAME, '') = ISNULL(d.CUST_NAME, '')
 AND ISNULL(o.EMAIL, '')     = ISNULL(d.EMAIL, '')
WHERE d.CUST_NO LIKE 'C9%';
SELECT * FROM stg.CustomerMergeMap;
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'CUST_MASTER', DuplicateCustNo, 'CUST_NO', DuplicateCustNo, 'WARNING',
       'Duplicate customer merged into ' + OriginalCustNo
FROM stg.CustomerMergeMap;
DELETE c
FROM stg.CUST_MASTER c
JOIN stg.CustomerMergeMap m ON m.DuplicateCustNo = c.CUST_NO;
SELECT COUNT(*) AS RowsLeft FROM stg.CUST_MASTER;

-- Step 3: clean names
ALTER TABLE stg.CUST_MASTER ADD FirstName VARCHAR(50) NULL, LastName VARCHAR(50) NULL;
GO
UPDATE stg.CUST_MASTER
SET FirstName = CASE
        WHEN CHARINDEX(',', CUST_NAME) > 0
            THEN LTRIM(RTRIM(SUBSTRING(CUST_NAME, CHARINDEX(',', CUST_NAME) + 1, 50)))
        ELSE LEFT(LTRIM(RTRIM(CUST_NAME)), CHARINDEX(' ', LTRIM(RTRIM(CUST_NAME)) + ' ') - 1)
    END,
    LastName = CASE
        WHEN CHARINDEX(',', CUST_NAME) > 0
            THEN LTRIM(RTRIM(LEFT(CUST_NAME, CHARINDEX(',', CUST_NAME) - 1)))
        ELSE LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(CUST_NAME)),
                 CHARINDEX(' ', LTRIM(RTRIM(CUST_NAME)) + ' ') + 1, 50)))
    END
WHERE CUST_NAME IS NOT NULL;
-- Proper case: first letter upper, rest lower
UPDATE stg.CUST_MASTER
SET FirstName = UPPER(LEFT(FirstName, 1)) + LOWER(SUBSTRING(FirstName, 2, 50)),
    LastName  = UPPER(LEFT(LastName, 1))  + LOWER(SUBSTRING(LastName, 2, 50))
WHERE CUST_NAME IS NOT NULL;
-- Log missing names as errors
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'CUST_MASTER', CUST_NO, 'CUST_NAME', NULL, 'ERROR', 'Customer name is missing'
FROM stg.CUST_MASTER WHERE CUST_NAME IS NULL;
SELECT TOP (20) CUST_NAME, FirstName, LastName FROM stg.CUST_MASTER ORDER BY NEWID();
-- Step 4: clean email and phone
ALTER TABLE stg.CUST_MASTER ADD CleanEmail VARCHAR(100) NULL, CleanPhone CHAR(12) NULL;
GO
UPDATE stg.CUST_MASTER
SET CleanEmail = LOWER(LTRIM(RTRIM(EMAIL)))
WHERE EMAIL LIKE '%_@_%._%';
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'CUST_MASTER', CUST_NO, 'EMAIL', EMAIL, 'WARNING', 'Invalid email set to NULL'
FROM stg.CUST_MASTER
WHERE EMAIL IS NOT NULL AND EMAIL NOT LIKE '%_@_%._%';
;WITH p AS (
    SELECT CUST_NO,
           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(PHONE,
               '(', ''), ')', ''), '-', ''), '.', ''), ' ', ''), '+', '') AS Digits
    FROM stg.CUST_MASTER
)
UPDATE c
SET CleanPhone = SUBSTRING(x.D10, 1, 3) + '-' + SUBSTRING(x.D10, 4, 3) + '-' + SUBSTRING(x.D10, 7, 4)
FROM stg.CUST_MASTER c
JOIN p ON p.CUST_NO = c.CUST_NO
CROSS APPLY (SELECT CASE WHEN LEN(p.Digits) = 11 AND LEFT(p.Digits, 1) = '1'
                         THEN RIGHT(p.Digits, 10) ELSE p.Digits END AS D10) x
WHERE LEN(x.D10) = 10 AND x.D10 NOT LIKE '%[^0-9]%';
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'CUST_MASTER', CUST_NO, 'PHONE', PHONE, 'WARNING', 'Phone not a valid 10-digit number, set to NULL'
FROM stg.CUST_MASTER
WHERE PHONE IS NOT NULL AND CleanPhone IS NULL;
SELECT TOP (20) EMAIL, CleanEmail, PHONE, CleanPhone
FROM stg.CUST_MASTER ORDER BY NEWID();

-- Step 5: clean state and ZIP
ALTER TABLE stg.CUST_MASTER ADD CleanState CHAR(2) NULL, CleanZip CHAR(5) NULL;
GO
UPDATE stg.CUST_MASTER
SET CleanState = CASE UPPER(LTRIM(RTRIM(ST)))
        WHEN 'IN' THEN 'IN'  WHEN 'INDIANA' THEN 'IN'  WHEN 'IND.' THEN 'IN'
        WHEN 'OH' THEN 'OH'  WHEN 'IL' THEN 'IL'  WHEN 'ILLINOIS' THEN 'IL'
        WHEN 'KY' THEN 'KY'
        ELSE NULL END;
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'CUST_MASTER', CUST_NO, 'ST', ST, 'WARNING', 'Unknown state value'
FROM stg.CUST_MASTER WHERE ST IS NOT NULL AND CleanState IS NULL;
UPDATE stg.CUST_MASTER
SET CleanZip = CASE
        WHEN LEFT(ZIP, 5) NOT LIKE '%[^0-9]%' AND LEN(ZIP) >= 5 THEN LEFT(ZIP, 5)
        WHEN LEN(ZIP) = 4 AND ZIP NOT LIKE '%[^0-9]%' THEN '0' + ZIP
        ELSE NULL END;
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'CUST_MASTER', CUST_NO, 'ZIP', ZIP, 'WARNING',
       CASE WHEN LEN(ZIP) = 4 THEN '4-digit ZIP padded with leading zero, please verify'
            ELSE 'Invalid ZIP set to NULL' END
FROM stg.CUST_MASTER
WHERE ZIP IS NOT NULL AND (CleanZip IS NULL OR LEN(ZIP) = 4);
SELECT ST, CleanState, COUNT(*) AS Cnt FROM stg.CUST_MASTER GROUP BY ST, CleanState;
SELECT TOP (20) ZIP, CleanZip FROM stg.CUST_MASTER WHERE ZIP <> CleanZip OR CleanZip IS NULL;

UPDATE stg.CUST_MASTER SET CleanZip = NULL WHERE LEN(ZIP) = 4;
UPDATE dbo.MigrationErrorLog
SET ErrorMessage = 'Truncated 4-digit ZIP set to NULL'
WHERE ColumnName = 'ZIP' AND LEN(BadValue) = 4;

-- Step 6: clean join date and status
ALTER TABLE stg.CUST_MASTER ADD CleanJoinDate DATE NULL, CleanStatus VARCHAR(10) NULL;
GO
UPDATE stg.CUST_MASTER
SET CleanJoinDate = COALESCE(
        TRY_CONVERT(DATE, JOIN_DT, 23),    -- 2024-05-01
        TRY_CONVERT(DATE, JOIN_DT, 101),   -- 05/01/2024
        TRY_CONVERT(DATE, JOIN_DT, 107),   -- May 01, 2024
        TRY_CONVERT(DATE, JOIN_DT, 112));  -- 20240501
INSERT dbo.MigrationErrorLog (SourceTable, SourceKey, ColumnName, BadValue, ErrorType, ErrorMessage)
SELECT 'CUST_MASTER', CUST_NO, 'JOIN_DT', JOIN_DT, 'WARNING', 'Invalid join date set to NULL'
FROM stg.CUST_MASTER WHERE JOIN_DT IS NOT NULL AND CleanJoinDate IS NULL;
UPDATE stg.CUST_MASTER
SET CleanStatus = CASE UPPER(LTRIM(RTRIM(ISNULL(STATUS_CD, ''))))
        WHEN 'A' THEN 'ACTIVE'  WHEN 'ACTIVE' THEN 'ACTIVE'
        WHEN 'I' THEN 'INACTIVE'
        ELSE 'UNKNOWN' END;
SELECT JOIN_DT, CleanJoinDate FROM stg.CUST_MASTER WHERE CleanJoinDate IS NULL;
SELECT STATUS_CD, CleanStatus, COUNT(*) AS Cnt FROM stg.CUST_MASTER GROUP BY STATUS_CD, CleanStatus;