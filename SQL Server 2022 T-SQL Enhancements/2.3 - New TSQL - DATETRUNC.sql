-- ************************************************************************ --
-- SQL Server 2022 New T-SQL Features: DATETRUNC
--
-- What it does:
--    Returns an input date truncated to a specified datepart
--
-- SYNTAX: 
--    DATETRUNC ( datepart, date )
--
-- New to SQL Server 2022: Entirely new function
-- Required Compatibility Level: N/A
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

USE AdventureWorks2019;
GO

-- Example 1: Workarounds for date truncation prior to DATETRUNC
-- These only go so far ... try determining the beginning of the quarter, for example
SELECT
	GETDATE() AS [CurrentDateTime]
	, CONVERT(DATETIME, CONVERT(VARCHAR(20), GETDATE(), 110)) AS [CurrentDay]
	, CONVERT(DATETIME, FORMAT(GETDATE(), 'yyyy-MM-dd HH:00')) AS [CurrentHour]
GO

-- Example 2: Truncate current date/time to different dateparts with DATETRUNC

DECLARE @d DATETIME2 = SYSUTCDATETIME();

SELECT NULL as [datepart], @d AS [value]
UNION ALL
SELECT 'YEAR', DATETRUNC(YEAR, @d)
UNION ALL
SELECT 'QUARTER', DATETRUNC(QUARTER, @d)
UNION ALL
SELECT 'MONTH', DATETRUNC(MONTH, @d)
UNION ALL
SELECT 'WEEK', DATETRUNC(WEEK, @d) -- Using the default DATEFIRST setting value of 7 (U.S. English)
UNION ALL
SELECT 'ISO_WEEK', DATETRUNC(ISO_WEEK, @d)
UNION ALL
SELECT 'DAYOFYEAR', DATETRUNC(DAYOFYEAR, @d)
UNION ALL
SELECT 'DAY', DATETRUNC(DAY, @d)
UNION ALL
SELECT 'HOUR', DATETRUNC(HOUR, @d)
UNION ALL
SELECT 'MINUTE', DATETRUNC(MINUTE, @d)
UNION ALL
SELECT 'SECOND', DATETRUNC(SECOND, @d)
UNION ALL
SELECT 'MILLISECOND', DATETRUNC(MILLISECOND, @d)
UNION ALL
SELECT 'MICROSECOND', DATETRUNC(MICROSECOND, @d);
GO



-- Example 3: DATETRUNC returns a truncated date of the same data type 
-- (and, if applicable, the same fractional time scale) as the input date. 

EXECUTE sp_describe_first_result_set @tsql=N'SELECT DATETRUNC(YEAR, SYSUTCDATETIME())';
EXECUTE sp_describe_first_result_set @tsql=N'SELECT DATETRUNC(YEAR, GETDATE())';
GO


-- Example 4: Error thrown when attempting to convert to a datepart not supported by input date

DECLARE @d time = '12:12:12.1234567';
SELECT DATETRUNC(year, @d);
GO


-- Example 5: DATETRUNC is not SARGable
CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_OrderDate ON Sales.SalesOrderHeader (
	OrderDate
);

-- SARGable
SELECT SalesOrderID, OrderDate, DATETRUNC(MONTH, OrderDate)
FROM Sales.SalesOrderHeader
WHERE OrderDate BETWEEN '2011-06-01' AND '2011-07-01'

-- Not SARGable
SELECT SalesOrderID, OrderDate, DATETRUNC(MONTH, OrderDate)
FROM Sales.SalesOrderHeader
WHERE DATETRUNC(MONTH, OrderDate) = '2011-06-01'
GO