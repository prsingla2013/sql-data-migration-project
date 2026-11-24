USE LegacyCRM;
GO
TRUNCATE TABLE dbo.CUST_MASTER;
TRUNCATE TABLE dbo.ORDER_HDR;
GO
DECLARE @First TABLE (i INT IDENTITY(0,1), n VARCHAR(50));
INSERT @First(n) VALUES ('James'),('Mary'),('Robert'),('Patricia'),('John'),('Jennifer'),
 ('Michael'),('Linda'),('David'),('Elizabeth'),('Priya'),('Raj'),('Anita'),('Carlos'),
 ('Maria'),('Wei'),('Fatima'),('Daniel'),('Sarah'),('Kevin');
DECLARE @Last TABLE (i INT IDENTITY(0,1), n VARCHAR(50));
INSERT @Last(n) VALUES ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),
 ('Miller'),('Davis'),('Patel'),('Sharma'),('Lopez'),('Wilson'),('Anderson'),('Thomas'),
 ('Taylor'),('Moore'),('Lee'),('Kumar'),('Clark'),('Lewis');
DECLARE @City TABLE (i INT IDENTITY(0,1), c VARCHAR(50), s VARCHAR(20), z VARCHAR(10));
INSERT @City(c,s,z) VALUES ('Indianapolis','IN','46204'),('Carmel','Indiana','46032'),
 ('Westfield','in','46074'),('Fishers','IN ','46038'),('Noblesville','ind.','46060'),
 ('Columbus','OH','43215'),('Chicago','Illinois','60601'),('Louisville','KY','40202');
;WITH N AS (
    SELECT TOP (1000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.CUST_MASTER (CUST_NO, CUST_NAME, EMAIL, PHONE, ADDR_LINE, CITY, ST, ZIP, JOIN_DT, STATUS_CD)
SELECT
    'C' + RIGHT('00000' + CAST(rn AS VARCHAR(10)), 5),
    CASE WHEN rn % 3 = 0  THEN l.n + ', ' + f.n
         WHEN rn % 17 = 0 THEN '  ' + UPPER(f.n + ' ' + l.n) + ' '
         ELSE f.n + ' ' + l.n END,
    CASE WHEN rn % 11 = 0 THEN NULL
         WHEN rn % 13 = 0 THEN LOWER(f.n) + '.' + LOWER(l.n) + 'gmail.com'
         ELSE LOWER(f.n) + '.' + LOWER(l.n) + CAST(rn AS VARCHAR(10)) + '@example.com' END,
    CASE rn % 5
         WHEN 0 THEN '(317) 555-' + RIGHT('0000' + CAST(rn AS VARCHAR(10)), 4)
         WHEN 1 THEN '317.555.'   + RIGHT('0000' + CAST(rn AS VARCHAR(10)), 4)
         WHEN 2 THEN '317555'     + RIGHT('0000' + CAST(rn AS VARCHAR(10)), 4)
         WHEN 3 THEN '+1 317-555-' + RIGHT('0000' + CAST(rn AS VARCHAR(10)), 4)
         ELSE CASE WHEN rn % 4 = 0 THEN 'N/A' ELSE '555-' + RIGHT('0000' + CAST(rn AS VARCHAR(10)), 4) END END,
    CAST(100 + rn AS VARCHAR(10)) + ' Main St',
    c.c,
    c.s,
    CASE WHEN rn % 19 = 0 THEN c.z + '-1234' WHEN rn % 23 = 0 THEN LEFT(c.z, 4) ELSE c.z END,
    CASE rn % 4
         WHEN 0 THEN CONVERT(VARCHAR(30), DATEADD(DAY, -rn * 3, '2025-12-31'), 23)
         WHEN 1 THEN CONVERT(VARCHAR(30), DATEADD(DAY, -rn * 3, '2025-12-31'), 101)
         WHEN 2 THEN CONVERT(VARCHAR(30), DATEADD(DAY, -rn * 3, '2025-12-31'), 107)
         ELSE CASE WHEN rn % 7 = 0 THEN '00/00/0000'
                   ELSE CONVERT(VARCHAR(30), DATEADD(DAY, -rn * 3, '2025-12-31'), 112) END END,
    CASE rn % 6 WHEN 0 THEN 'I' WHEN 1 THEN 'active' WHEN 2 THEN '' ELSE 'A' END
FROM N
JOIN @First f ON f.i = N.rn % 20
JOIN @Last  l ON l.i = (N.rn / 20) % 20
JOIN @City  c ON c.i = N.rn % 8;
-- Exact duplicate rows
INSERT dbo.CUST_MASTER SELECT * FROM dbo.CUST_MASTER
WHERE CAST(RIGHT(CUST_NO, 5) AS INT) % 50 = 0;
-- Same person entered twice under a different customer number
INSERT dbo.CUST_MASTER (CUST_NO, CUST_NAME, EMAIL, PHONE, ADDR_LINE, CITY, ST, ZIP, JOIN_DT, STATUS_CD)
SELECT 'C9' + RIGHT(CUST_NO, 4), CUST_NAME, EMAIL, PHONE, ADDR_LINE, CITY, ST, ZIP, JOIN_DT, STATUS_CD
FROM dbo.CUST_MASTER WHERE CAST(RIGHT(CUST_NO, 5) AS INT) % 97 = 0;
-- Missing names
UPDATE dbo.CUST_MASTER SET CUST_NAME = NULL WHERE CUST_NO IN ('C00333','C00666','C00999');
GO
;WITH N AS (
    SELECT TOP (3000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT dbo.ORDER_HDR (ORD_NO, CUST_NO, ORD_DT, ORD_AMT, ORD_STATUS)
SELECT
    'O' + RIGHT('000000' + CAST(rn AS VARCHAR(10)), 6),
    CASE WHEN rn % 150 = 0 THEN 'C99999'
         ELSE 'C' + RIGHT('00000' + CAST((rn % 1000) + 1 AS VARCHAR(10)), 5) END,
    CASE rn % 3
         WHEN 0 THEN CONVERT(VARCHAR(30), DATEADD(DAY, -(rn % 700), '2026-06-30'), 23)
         WHEN 1 THEN CONVERT(VARCHAR(30), DATEADD(DAY, -(rn % 700), '2026-06-30'), 101)
         ELSE CASE WHEN rn % 200 = 0 THEN ''
                   ELSE CONVERT(VARCHAR(30), DATEADD(DAY, -(rn % 700), '2026-06-30'), 107) END END,
    CASE rn % 4
         WHEN 0 THEN '$' + FORMAT((rn % 500) * 3.25 + 10, 'N2')
         WHEN 1 THEN CAST(CAST((rn % 500) * 3.25 + 10 AS DECIMAL(10,2)) AS VARCHAR(30))
         WHEN 2 THEN CASE WHEN rn % 120 = 0 THEN 'N/A'
                          ELSE CAST(CAST((rn % 500) * 3.25 + 10 AS DECIMAL(10,2)) AS VARCHAR(30)) END
         ELSE CASE WHEN rn % 250 = 0 THEN '-45.00'
                   ELSE CAST(CAST((rn % 500) * 3.25 + 10 AS DECIMAL(10,2)) AS VARCHAR(30)) END END,
    CASE rn % 5 WHEN 0 THEN 'SHIPPED' WHEN 1 THEN 'shipped' WHEN 2 THEN 'Cancelled'
                WHEN 3 THEN 'OPEN' ELSE 'cncl' END
FROM N;
GO
-- Take a look
--SELECT 'CUST_MASTER' AS TableName, COUNT(*) AS TotalRows FROM dbo.CUST_MASTER
--UNION ALL
--SELECT 'ORDER_HDR', COUNT(*) FROM dbo.ORDER_HDR;
--SELECT TOP (20) * FROM dbo.CUST_MASTER ORDER BY NEWID();
--SELECT TOP (20) * FROM dbo.ORDER_HDR  ORDER BY NEWID();