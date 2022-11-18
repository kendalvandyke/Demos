-- ************************************************************************ --
-- SQL Server 2022 New T-SQL Features: APPROXIMATE PERCENTILE continuous and discreet
--
-- What it does:
--    APPROX_PERCENTILE_DISC: Returns an approximated value from the set column values that based on the provided percentile.
--    APPROX_PERCENTILE_CONT: Returns an approximated interpolated value from the distribution of column values based on the provided percentile
--    
-- SYNTAX: 
--    APPROX_PERCENTILE_DISC (numeric_literal) WITHIN GROUP (ORDER BY order_by_expression [ASC|DESC])
--    APPROX_PERCENTILE_CONT (numeric_literal) WITHIN GROUP (ORDER BY order_by_expression [ASC|DESC])    
--
-- New to SQL Server 2022: Entirely new functions
-- Required Compatibility Level: N/A
--
-- Documentation: 
--    APPROX_PERCENTILE_CONT: https://docs.microsoft.com/en-us/sql/t-sql/functions/approx-percentile-cont-transact-sql?view=sql-server-ver16
--    APPROX_PERCENTILE_DISC: https://docs.microsoft.com/en-us/sql/t-sql/functions/approx-percentile-disc-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

/*
Notes:
	Approximate percentile functions use KLL sketch. The sketch is built by reading the stream of data. Results will vary between executions.
	approx_percentile_* functions are aggregate functions with nondeterministic nature, whereas percentile functions are analytical functions
	This function provides rank-based error guarantees not value based. The function implementation guarantees up to a 1.33% error.

	These examples use the "bigger" version of the WideWorldImportersDW sample database. Make WideWorldImportersDW with this script: 
	https://github.com/microsoft/bobsql/blob/master/sql2019book/ch2_intelligent_performance/iqp/extendwwidw.sql
*/

-- A. Let's look at a "large enough" dataset to demonstrate the behavior (3,702,592 rows)
-- Show actual execution plans to see the difference in what's happening under the hood
USE WideWorldImportersDW
GO
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON
GO

-- Start with returning the 95th percentile for order total (including tax) by employee using PERCENTILE_CONT
SELECT DISTINCT de.Employee
	, PERCENTILE_CONT(0.95) 
		WITHIN GROUP (ORDER BY foh.[Total Including Tax]) 
		OVER (PARTITION BY de.Employee) AS [95 percentile CONT] 
FROM Fact.OrderHistory AS foh
	INNER JOIN Dimension.Employee AS de ON foh.[Salesperson Key] = de.[Employee Key]
ORDER BY de.Employee;
GO
SET STATISTICS TIME,IO OFF
GO

-- Now achieve (almost) the same result with APPROX_PERCENTILE_CONT
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON
GO

SELECT de.Employee
	, APPROX_PERCENTILE_CONT(0.95) 
	WITHIN GROUP (ORDER BY foh.[Total Including Tax]) AS [95 percentile APPROX_CONT]  
FROM Fact.OrderHistory AS foh
	INNER JOIN Dimension.Employee AS de ON foh.[Salesperson Key] = de.[Employee Key]
GROUP BY de.Employee
ORDER BY de.Employee;
GO
SET STATISTICS TIME,IO OFF
GO
