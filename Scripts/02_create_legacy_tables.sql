USE LegacyCRM;
GO
CREATE TABLE dbo.CUST_MASTER (
    CUST_NO    VARCHAR(20),   -- no primary key in old system
    CUST_NAME  VARCHAR(200),  -- "Last, First" or "First Last"
    EMAIL      VARCHAR(200),
    PHONE      VARCHAR(50),   -- mixed formats
    ADDR_LINE  VARCHAR(300),
    CITY       VARCHAR(100),
    ST         VARCHAR(50),   -- 'IN', 'Indiana', 'ind.'
    ZIP        VARCHAR(20),
    JOIN_DT    VARCHAR(30),   -- dates stored as text
    STATUS_CD  VARCHAR(10)    -- 'A', 'I', 'active', blank
);
GO
CREATE TABLE dbo.ORDER_HDR (
    ORD_NO     VARCHAR(20),
    CUST_NO    VARCHAR(20),   -- may point to missing customers
    ORD_DT     VARCHAR(30),
    ORD_AMT    VARCHAR(30),   -- '$1,250.00', '1250', 'N/A'
    ORD_STATUS VARCHAR(20)
);
GO