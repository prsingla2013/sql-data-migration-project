USE ModernCRM;
GO
SELECT 'Orders with no matching customer' AS CheckName, COUNT(*) AS Issues
FROM dbo.Orders o LEFT JOIN dbo.Customer c ON c.CustomerID = o.CustomerID
WHERE c.CustomerID IS NULL
UNION ALL
SELECT 'Duplicate LegacyCustNo', COUNT(*) - COUNT(DISTINCT LegacyCustNo) FROM dbo.Customer
UNION ALL
SELECT 'Duplicate LegacyOrdNo', COUNT(*) - COUNT(DISTINCT LegacyOrdNo) FROM dbo.Orders
UNION ALL
SELECT 'Bad phone format', COUNT(*) FROM dbo.Customer
WHERE Phone IS NOT NULL AND Phone NOT LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
UNION ALL
SELECT 'Bad ZIP format', COUNT(*) FROM dbo.Customer
WHERE ZipCode IS NOT NULL AND ZipCode NOT LIKE '[0-9][0-9][0-9][0-9][0-9]'
UNION ALL
SELECT 'Negative order amount', COUNT(*) FROM dbo.Orders WHERE OrderAmount < 0
UNION ALL
SELECT 'Order amount total mismatch',
       CASE WHEN (SELECT SUM(OrderAmount) FROM dbo.Orders) =
                 (SELECT SUM(CleanAmount) FROM stg.ORDER_HDR
                  WHERE CustomerID IS NOT NULL AND CleanOrderDate IS NOT NULL)
            THEN 0 ELSE 1 END;

SELECT SourceTable, ErrorType, ColumnName, COUNT(*) AS Cnt
FROM dbo.MigrationErrorLog
GROUP BY SourceTable, ErrorType, ColumnName
ORDER BY SourceTable, ErrorType, ColumnName;
