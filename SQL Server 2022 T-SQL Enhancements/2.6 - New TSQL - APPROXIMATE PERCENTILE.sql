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

-- Let's start with looking at the 95th percentile for order total price by employee using PERCENTILE_*
-- CONT and DISC will be the same in this example because there are no NULL values in the data
SELECT DISTINCT de.Employee
	, PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY foh.Quantity) OVER (PARTITION BY de.Employee) AS [Quantity 95 percentile CONT] 
	--, PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY foh.Quantity) OVER (PARTITION BY de.Employee)AS [Quantity 95 percentile DISC]
FROM Fact.OrderHistory AS foh
	INNER JOIN Dimension.Employee AS de ON foh.[Salesperson Key] = de.[Employee Key]
ORDER BY de.Employee



/*
Table 'Employee'. Scan count 1, logical reads 5, physical reads 1, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'OrderHistory'. Scan count 9, logical reads 94423, physical reads 0, page server reads 0, read-ahead reads 94353, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 44, logical reads 21093555, physical reads 0, page server reads 0, read-ahead reads 16787, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 65283 ms,  elapsed time = 29976 ms.
*/


-- Now let's look at how to achieve the same thing with APPROX_PERCENTILE_*
-- APPROX_PERCENTILE_* are aggregate functions (whereas PERCENTILE_* are analytic)
-- The function 'APPROX_PERCENTILE_CONT' is not a valid windowing function, and cannot be used with the OVER clause.
-- Also, unlike PERCENTILE_*, APPROX_PERCENTILE_* can be used with a GROUP BY clause
-- Finally, results may change between executions even if the data does not due to the algorithm used to calculate APPROX_PERCENTILE_*
SELECT de.Employee
	, APPROX_PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY foh.Quantity)   
	--, APPROX_PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY foh.Quantity)   
FROM Fact.OrderHistory AS foh
	INNER JOIN Dimension.Employee AS de ON foh.[Salesperson Key] = de.[Employee Key]
GROUP BY de.Employee
ORDER BY de.Employee

/*
Table 'OrderHistory'. Scan count 9, logical reads 94423, physical reads 0, page server reads 0, read-ahead reads 94353, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Employee'. Scan count 0, logical reads 202, physical reads 1, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 101, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 7231 ms,  elapsed time = 4863 ms.
*/