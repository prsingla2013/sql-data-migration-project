USE ModernCRM;
GO
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customer', 'U') IS NOT NULL DROP TABLE dbo.Customer;
IF OBJECT_ID('dbo.MigrationErrorLog', 'U') IS NOT NULL DROP TABLE dbo.MigrationErrorLog;
GO
CREATE TABLE dbo.Customer (
    CustomerID     INT IDENTITY(1,1) PRIMARY KEY,
    LegacyCustNo   VARCHAR(10)  NOT NULL UNIQUE,
    FirstName      VARCHAR(50)  NOT NULL,
    LastName       VARCHAR(50)  NOT NULL,
    Email          VARCHAR(100) NULL,
    Phone          CHAR(12)     NULL,
    AddressLine    VARCHAR(100) NULL,
    City           VARCHAR(50)  NULL,
    StateCode      CHAR(2)      NULL,
    ZipCode        CHAR(5)      NULL,
    JoinDate       DATE         NULL,
    CustomerStatus VARCHAR(10)  NOT NULL
        CHECK (CustomerStatus IN ('ACTIVE', 'INACTIVE', 'UNKNOWN')),
    CreatedAt      DATETIME2    NOT NULL DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.Orders (
    OrderID        INT IDENTITY(1,1) PRIMARY KEY,
    LegacyOrdNo    VARCHAR(10)   NOT NULL UNIQUE,
    CustomerID     INT           NOT NULL
        REFERENCES dbo.Customer(CustomerID),
    OrderDate      DATE          NOT NULL,
    OrderAmount    DECIMAL(10,2) NOT NULL CHECK (OrderAmount >= 0),
    OrderStatus    VARCHAR(10)   NOT NULL
        CHECK (OrderStatus IN ('SHIPPED', 'CANCELLED', 'OPEN')),
    CreatedAt      DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
CREATE TABLE dbo.MigrationErrorLog (
    ErrorID        INT IDENTITY(1,1) PRIMARY KEY,
    SourceTable    VARCHAR(50)  NOT NULL,
    SourceKey      VARCHAR(20)  NULL,
    ColumnName     VARCHAR(50)  NULL,
    BadValue       VARCHAR(200) NULL,
    ErrorType      VARCHAR(10)  NOT NULL CHECK (ErrorType IN ('ERROR', 'WARNING')),
    ErrorMessage   VARCHAR(500) NOT NULL,
    LoggedAt       DATETIME2    NOT NULL DEFAULT SYSDATETIME()
);
GO
SELECT name FROM sys.tables ORDER BY name;