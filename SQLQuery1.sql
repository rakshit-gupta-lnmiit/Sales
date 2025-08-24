-- ===================================================================
-- FINAL ENTERPRISE DATA WAREHOUSE SCHEMA v4
--
-- Business Process 1: Sales Analytics
-- Business Process 2: Employee Attendance Analytics
-- ===================================================================

-- Drop existing tables in order of dependency to start fresh
DROP TABLE IF EXISTS FactSales;
DROP TABLE IF EXISTS FactEmployeeAttendance; -- New attendance fact table
DROP TABLE IF EXISTS DimProduct;
DROP TABLE IF EXISTS DimProductSubcategory;
DROP TABLE IF EXISTS DimProductCategory;
DROP TABLE IF EXISTS DimStore;
DROP TABLE IF EXISTS DimCustomer;
DROP TABLE IF EXISTS DimGeography;
DROP TABLE IF EXISTS DimEmployee;
DROP TABLE IF EXISTS DimEmployeeRecruitmentAddress;
DROP TABLE IF EXISTS DimDate;
DROP TABLE IF EXISTS DimTimeOfDay;
GO

-- =============================================
-- SHARED & CORE DIMENSIONS
-- These dimensions can be used by multiple fact tables
-- =============================================

CREATE TABLE DimGeography (
    GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
    City VARCHAR(100) NOT NULL,
    Locality VARCHAR(100),
    StateProvince VARCHAR(100) NOT NULL,
    CountryRegion VARCHAR(100) NOT NULL
);

CREATE TABLE DimEmployeeRecruitmentAddress (
    RecruitmentAddressKey INT IDENTITY(1,1) PRIMARY KEY,
    StateProvince VARCHAR(100) NOT NULL,
    CountryRegion VARCHAR(100) NOT NULL
);

CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    DayNumberOfMonth TINYINT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    CalendarQuarter TINYINT NOT NULL,
    CalendarYear SMALLINT NOT NULL
);

CREATE TABLE DimEmployee (
    EmployeeKey INT IDENTITY(1,1) PRIMARY KEY,
    RecruitmentAddressKey INT,
    EmployeeCity VARCHAR(100),
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Title VARCHAR(100),
    CONSTRAINT FK_Employee_RecruitmentAddress FOREIGN KEY (RecruitmentAddressKey) REFERENCES DimEmployeeRecruitmentAddress(RecruitmentAddressKey)
);

-- =============================================
-- SCHEMA 1: SALES ANALYTICS
-- Dimensions specific to Sales
-- =============================================

CREATE TABLE DimTimeOfDay (
    TimeKey INT PRIMARY KEY,
    HourOfDay TINYINT NOT NULL,
    TimeOfDayBracket VARCHAR(20) NOT NULL
);

CREATE TABLE DimProductCategory (
    ProductCategoryKey INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL
);

CREATE TABLE DimProductSubcategory (
    ProductSubcategoryKey INT IDENTITY(1,1) PRIMARY KEY,
    SubcategoryName VARCHAR(100) NOT NULL,
    ProductCategoryKey INT NOT NULL,
    CONSTRAINT FK_Subcategory_Category FOREIGN KEY (ProductCategoryKey) REFERENCES DimProductCategory(ProductCategoryKey)
);

CREATE TABLE DimProduct (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductSubcategoryKey INT,
    ProductSKU VARCHAR(50) NOT NULL,
    ProductName VARCHAR(255) NOT NULL,
    StandardCost DECIMAL(19, 4),
    CONSTRAINT FK_Product_Subcategory FOREIGN KEY (ProductSubcategoryKey) REFERENCES DimProductSubcategory(ProductSubcategoryKey)
);

CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    GeographyKey INT,
    CustomerName VARCHAR(255) NOT NULL,
    CONSTRAINT FK_Customer_Geography FOREIGN KEY (GeographyKey) REFERENCES DimGeography(GeographyKey)
);

CREATE TABLE DimStore (
    StoreKey INT IDENTITY(1,1) PRIMARY KEY,
    GeographyKey INT,
    StoreAlternateID VARCHAR(20) NOT NULL,
    StoreName VARCHAR(100) NOT NULL,
    OpenDate DATE,
    CONSTRAINT FK_Store_Geography FOREIGN KEY (GeographyKey) REFERENCES DimGeography(GeographyKey)
);

-- Fact Table for Sales
CREATE TABLE FactSales (
    SalesKey INT IDENTITY(1,1) NOT NULL,
    -- Date and Time Keys
    OrderDateKey INT NOT NULL,
    OrderTimeKey INT NOT NULL,
    DueDateKey INT NOT NULL, -- Added back as requested
    ShipDateKey INT,
    -- Dimension Keys
    ProductKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    StoreKey INT NOT NULL,
    EmployeeKey INT NOT NULL,
    -- Degenerate Dimension
    SalesOrderNumber VARCHAR(50) NOT NULL,
    -- Measures
    OrderQuantity SMALLINT NOT NULL,
    UnitPrice DECIMAL(19, 4) NOT NULL,
    SalesAmount DECIMAL(19, 4) NOT NULL,
    
    -- Constraints
    CONSTRAINT PK_FactSales PRIMARY KEY (SalesKey),
    CONSTRAINT FK_FactSales_DimDate_Order FOREIGN KEY (OrderDateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactSales_DimDate_Due FOREIGN KEY (DueDateKey) REFERENCES DimDate(DateKey), -- Added constraint
    CONSTRAINT FK_FactSales_DimTimeOfDay FOREIGN KEY (OrderTimeKey) REFERENCES DimTimeOfDay(TimeKey),
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),
    CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSales_DimStore FOREIGN KEY (StoreKey) REFERENCES DimStore(StoreKey),
    CONSTRAINT FK_FactSales_DimEmployee FOREIGN KEY (EmployeeKey) REFERENCES DimEmployee(EmployeeKey)
);

-- =============================================
-- SCHEMA 2: EMPLOYEE ATTENDANCE ANALYTICS
-- Transactional Fact Table
-- =============================================
CREATE TABLE FactEmployeeAttendance (
    AttendanceKey INT IDENTITY(1,1) PRIMARY KEY,
    -- Dimension Keys (reusing shared dimensions)
    DateKey INT NOT NULL,
    EmployeeKey INT NOT NULL,
    -- Measures and Event Data
    LoginTime TIME, -- e.g., '09:02:15'
    LogoutTime TIME, -- e.g., '17:35:10'
    HoursWorked AS DATEDIFF(MINUTE, LoginTime, LogoutTime) / 60.0, -- Calculated column for analysis
    
    -- Constraints
    CONSTRAINT FK_FactEmployeeAttendance_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactEmployeeAttendance_DimEmployee FOREIGN KEY (EmployeeKey) REFERENCES DimEmployee(EmployeeKey)
);