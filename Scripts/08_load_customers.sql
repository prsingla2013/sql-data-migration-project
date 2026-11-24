USE ModernCRM;
GO
INSERT dbo.Customer (LegacyCustNo, FirstName, LastName, Email, Phone,
                     AddressLine, City, StateCode, ZipCode, JoinDate, CustomerStatus)
SELECT CUST_NO, FirstName, LastName, CleanEmail, CleanPhone,
       LTRIM(RTRIM(ADDR_LINE)), LTRIM(RTRIM(CITY)), CleanState, CleanZip,
       CleanJoinDate, CleanStatus
FROM stg.CUST_MASTER
WHERE CUST_NAME IS NOT NULL;     -- the 3 ERROR rows stay out
SELECT @@ROWCOUNT AS CustomersLoaded;
-- Reconciliation: source = loaded + rejected + merged/removed
SELECT
    (SELECT COUNT(*) FROM LegacyCRM.dbo.CUST_MASTER)                          AS SourceRows,
    (SELECT COUNT(*) FROM dbo.Customer)                                        AS Loaded,
    (SELECT COUNT(*) FROM dbo.MigrationErrorLog WHERE ErrorType = 'ERROR'
        AND SourceTable = 'CUST_MASTER')                                       AS Rejected,
    (SELECT COUNT(*) FROM stg.CustomerMergeMap)                                AS Merged,
    20																			AS ExactDupsRemoved;