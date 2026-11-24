USE ModernCRM;
GO
INSERT dbo.Orders (LegacyOrdNo, CustomerID, OrderDate, OrderAmount, OrderStatus)
SELECT LTRIM(RTRIM(ORD_NO)), CustomerID, CleanOrderDate, CleanAmount, CleanStatus
FROM stg.ORDER_HDR
WHERE CustomerID IS NOT NULL
  AND CleanOrderDate IS NOT NULL
  AND CleanAmount >= 0
  AND CleanStatus IS NOT NULL;
SELECT @@ROWCOUNT AS OrdersLoaded;

SELECT (SELECT COUNT(*) FROM LegacyCRM.dbo.ORDER_HDR) AS SourceRows,
       (SELECT COUNT(*) FROM dbo.Orders) AS Loaded,
       (SELECT COUNT(DISTINCT SourceKey) FROM dbo.MigrationErrorLog
         WHERE SourceTable = 'ORDER_HDR' AND ErrorType = 'ERROR') AS RejectedOrders;
