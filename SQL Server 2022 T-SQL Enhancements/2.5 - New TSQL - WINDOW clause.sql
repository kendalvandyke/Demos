-- ************************************************************************ --
-- SQL Server 2022 New T-SQL Features: SELECT window clause (named window definitions)
--
-- What it does:
--    Named window definition in the WINDOW clause determines the partitioning and ordering of a rowset 
--    before the window function which uses the window in OVER clause is applied.
--
-- SYNTAX: 
--    WINDOW window_name AS (
--       [ reference_window_name ]   
--       [ <PARTITION BY clause> ]  
--       [ <ORDER BY clause> ]   
--       [ <ROW or RANGE clause> ]  
--    ) 
--
-- New to SQL Server 2022: Entirely new syntax
-- Required Compatibility Level: 160
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/queries/select-window-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

USE AdventureWorks2019
GO

/*
The WINDOW clause functionality is available only under compatibility level 160 or higher. 
If your database compatibility level is lower than 160, SQL Server cannot execute queries with the WINDOW clause.
*/
ALTER DATABASE [AdventureWorks2019] SET COMPATIBILITY_LEVEL =  160


-- Example 1: Using a named window

--Before WINDOW clause
SELECT SalesOrderID
	   , ProductID
	   , OrderQty
	   , SUM (OrderQty) OVER (PARTITION BY SalesOrderID) AS [Total]
	   , AVG (OrderQty) OVER (PARTITION BY SalesOrderID) AS [Avg]
	   , COUNT (OrderQty) OVER (PARTITION BY SalesOrderID) AS [Count]
	   , MIN (OrderQty) OVER (PARTITION BY SalesOrderID) AS [Min]
	   , MAX (OrderQty) OVER (PARTITION BY SalesOrderID) AS [Max]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
ORDER BY SalesOrderID, ProductID;


-- Using WINDOW clause
SELECT SalesOrderID
	   , ProductID
	   , OrderQty
	   , SUM (OrderQty) OVER win AS [Total]
	   , AVG (OrderQty) OVER win AS [Avg]
	   , COUNT (OrderQty) OVER win AS [Count]
	   , MIN (OrderQty) OVER win AS [Min]
	   , MAX (OrderQty) OVER win AS [Max]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 ) 
WINDOW win AS (PARTITION BY SalesOrderID)
ORDER BY SalesOrderID, ProductID;


-- Example 2: Multiple named windows

-- Before WINDOW clause
SELECT SalesOrderID
	   , ProductID
	   , OrderQty AS Qty
	   , SUM (OrderQty) OVER (ORDER BY SalesOrderID, ProductID) AS [Total]
	   , AVG (OrderQty) OVER (PARTITION BY SalesOrderID ORDER BY SalesOrderID, ProductID) AS [Avg]
	   , COUNT (OrderQty) OVER (ORDER BY SalesOrderID, ProductID
								ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING
						  ) AS [Count]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
	  AND ProductID LIKE '71%'
ORDER BY SalesOrderID, ProductID;


-- Using WINDOW clause
SELECT SalesOrderID
	   , ProductID
	   , OrderQty AS Qty
	   , SUM (OrderQty) OVER win1 AS [Total]
	   , AVG (OrderQty) OVER win2 AS [Avg]
	   , COUNT (OrderQty) OVER win3 AS [Count]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
	  AND ProductID LIKE '71%' 
WINDOW win1 AS (ORDER BY SalesOrderID, ProductID)
	   , win2 AS (PARTITION BY SalesOrderID ORDER BY SalesOrderID, ProductID )
	   , win3 AS (ORDER BY SalesOrderID, ProductID ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING)
ORDER BY SalesOrderID, ProductID;





-- Example 3: Defining additional specifications on a named window

-- Before WINDOW clause
SELECT SalesOrderID
	   , ProductID
	   , OrderQty AS Qty
	   , SUM (OrderQty) OVER (ORDER BY SalesOrderID, ProductID) AS [Total]
	   , AVG (OrderQty) OVER (PARTITION BY SalesOrderID ORDER BY SalesOrderID, ProductID) AS [Avg]
	   , COUNT (OrderQty) OVER (ORDER BY SalesOrderID, ProductID
								ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING
						  ) AS [Count]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
	  AND ProductID LIKE '71%'
ORDER BY SalesOrderID, ProductID;


-- Using WINDOW clause
SELECT SalesOrderID
	   , ProductID
	   , OrderQty AS Qty
	   , SUM (OrderQty) OVER win AS [Total]
	   , AVG (OrderQty) OVER (win PARTITION BY SalesOrderID) AS [Avg]
	   , COUNT (OrderQty) OVER (win ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING) AS [Count]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
	  AND ProductID LIKE '71%' 
WINDOW win AS (ORDER BY SalesOrderID, ProductID)
ORDER BY SalesOrderID, ProductID;
GO




-- Example 4: Using named windows as forward and backward references

--Before WINDOW clause
SELECT SalesOrderID
	   , ProductID
	   , OrderQty AS Qty
	   , SUM (OrderQty) OVER (ORDER BY SalesOrderID, ProductID) AS [Total]
	   , AVG (OrderQty) OVER (PARTITION BY SalesOrderID ORDER BY SalesOrderID, ProductID) AS [Avg]
	   , COUNT (OrderQty) OVER (ORDER BY SalesOrderID, ProductID
								ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING
						  ) AS [Count]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
	  AND ProductID LIKE '71%'
ORDER BY SalesOrderID, ProductID;
GO

-- Using WINDOW clause
--"win2" references "win1" for its' definition, adding a PARTITION BY
--"win3" references "win1" for its' definition, adding a ROWS BETWEEN ...
SELECT SalesOrderID
	   , ProductID
	   , OrderQty AS Qty
	   , SUM (OrderQty) OVER win1 AS [Total]
	   , AVG (OrderQty) OVER win2 AS [Avg]
	   , COUNT (OrderQty) OVER win3 AS [Count]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
	  AND ProductID LIKE '71%' 
WINDOW win1 AS (ORDER BY SalesOrderID, ProductID)
	   , win2 AS (win1 PARTITION BY SalesOrderID)
	   , win3 AS (win1 ROWS BETWEEN UNBOUNDED PRECEDING AND 1 FOLLOWING)
ORDER BY SalesOrderID, ProductID;
GO



-- Example 5: Cyclic references result in an error

SELECT SalesOrderID
	   , ProductID
	   , OrderQty AS Qty
	   , SUM (OrderQty) OVER win1 AS Total
	   , AVG (OrderQty) OVER win2 AS [Avg]
FROM Sales.SalesOrderDetail
WHERE SalesOrderID IN ( 43659, 43664 )
	  AND ProductID LIKE '71%' 
WINDOW win1 AS(win3)
	   , win2 AS(win1 ORDER BY SalesOrderID, ProductID)
	   , win3 AS(win2 PARTITION BY SalesOrderID)
ORDER BY SalesOrderID, ProductID;
