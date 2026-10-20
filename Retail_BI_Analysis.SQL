/*
North Star E-Commerce — Retail BI Analysis
Tools: SQL Server / SSMS
Database: RetailBI (adjust USE statement if your database has a different name)

Purpose:
Reusable analysis queries for the Retail BI portfolio project.


- NetSales = Quantity * UnitPrice * (1 - DiscountPct)
- CostOfGoods = Quantity * UnitCost
- GrossProfit = NetSales - CostOfGoods
- GrossMarginPct = GrossProfit / NetSales * 100
- ShippingRevenue is not included in NetSales in dbo.vw_Sales.
*/

-- 1. Overall data validation and headline metrics
SELECT
    COUNT(DISTINCT OrderID) AS TotalOrders,
    COUNT(DISTINCT CustomerID) AS TotalCustomers,
    SUM(NetSales) AS TotalNetSales,
    SUM(GrossProfit) AS TotalGrossProfit,
    SUM(Quantity) AS UnitsSold
FROM dbo.vw_Sales;


-- 2. Net sales by country
SELECT
    Country,
    CAST(SUM(NetSales) AS DECIMAL(18, 2)) AS NetSales,
    COUNT(DISTINCT OrderID) AS OrderCount,
    COUNT(DISTINCT CustomerID) AS CustomerCount,
    CAST(
        SUM(NetSales) / NULLIF(COUNT(DISTINCT OrderID) * 1.0, 0)
        AS DECIMAL(18, 2)
    ) AS AverageOrderValue
FROM dbo.vw_Sales
GROUP BY Country
ORDER BY SUM(NetSales) DESC;


-- 3. Monthly sales trends for 2025
SELECT
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS OrderMonth,
    COUNT(DISTINCT OrderID) AS Orders,
    COUNT(DISTINCT CustomerID) AS Customers,
    CAST(SUM(NetSales) AS DECIMAL(18, 2)) AS NetSales
FROM dbo.vw_Sales
WHERE OrderDate >= '2025-01-01'
  AND OrderDate <  '2026-01-01'
GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY OrderMonth;


-- 4. Seasonal category comparison: average monthly sales in Nov-Dec
--    compared with Jan-Oct. This compares monthly averages, not total periods.
WITH CategoryPeriods AS (
    SELECT
        Category,
        SUM(CASE
            WHEN OrderDate >= '2025-11-01'
             AND OrderDate <  '2026-01-01'
            THEN NetSales ELSE 0
        END) AS NovDecSales,
        SUM(CASE
            WHEN OrderDate >= '2025-01-01'
             AND OrderDate <  '2025-11-01'
            THEN NetSales ELSE 0
        END) AS JanOctSales
    FROM dbo.vw_Sales
    WHERE OrderDate >= '2025-01-01'
      AND OrderDate <  '2026-01-01'
    GROUP BY Category
)
SELECT
    Category,
    CAST(NovDecSales / 2.0 AS DECIMAL(18, 2)) AS AvgMonthlyNovDec,
    CAST(JanOctSales / 10.0 AS DECIMAL(18, 2)) AS AvgMonthlyJanOct,
    CAST(
        100.0 * ((NovDecSales / 2.0) / NULLIF(JanOctSales / 10.0, 0) - 1)
        AS DECIMAL(8, 2)
    ) AS SeasonalIncreasePct
FROM CategoryPeriods
ORDER BY SeasonalIncreasePct DESC;


-- 5. Profitability by product category
SELECT
    Category,
    CAST(SUM(NetSales) AS DECIMAL(18, 2)) AS NetSales,
    CAST(SUM(GrossProfit) AS DECIMAL(18, 2)) AS GrossProfit,
    CAST(
        100.0 * SUM(GrossProfit) / NULLIF(SUM(NetSales), 0)
        AS DECIMAL(8, 2)
    ) AS GrossMarginPct,
    CAST(AVG(DiscountPct) * 100.0 AS DECIMAL(8, 2)) AS AvgDiscountPct
FROM dbo.vw_Sales
GROUP BY Category
ORDER BY SUM(GrossProfit) DESC;


-- 6. Customer order-frequency distribution
--    Validate this pattern before presenting it as a business conclusion.
WITH CustomerOrderCounts AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT OrderID) AS OrderCount
    FROM dbo.Orders
    GROUP BY CustomerID
)
SELECT
    OrderCount,
    COUNT(*) AS NumberOfCustomers,
    CAST(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()
        AS DECIMAL(6, 2)
    ) AS CustomerPct
FROM CustomerOrderCounts
GROUP BY OrderCount
ORDER BY OrderCount;


-- 7. Highest-revenue products
SELECT TOP (10)
    ProductName,
    Category,
    CAST(SUM(NetSales) AS DECIMAL(18, 2)) AS NetSales,
    SUM(Quantity) AS UnitsSold,
    CAST(SUM(GrossProfit) AS DECIMAL(18, 2)) AS GrossProfit
FROM dbo.vw_Sales
GROUP BY ProductName, Category
ORDER BY SUM(NetSales) DESC;


-- 8. Monthly order and average-order-value comparison
SELECT
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonthNumber,
    COUNT(DISTINCT OrderID) AS Orders,
    CAST(SUM(NetSales) AS DECIMAL(18, 2)) AS NetSales,
    CAST(
        SUM(NetSales) / NULLIF(COUNT(DISTINCT OrderID) * 1.0, 0)
        AS DECIMAL(18, 2)
    ) AS AverageOrderValue
FROM dbo.vw_Sales
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonthNumber;
