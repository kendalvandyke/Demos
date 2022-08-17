USE AdventureWorks2019;
GO

-- Number of NULL and non-NULL values for SalesPersonID in Sales.SalesOrderHeader 
SELECT SUM (IIF(SalesPersonID IS NULL, 1, 0)) AS [NULL_count]
	, SUM (IIF(SalesPersonID IS NULL, 0, 1)) AS [non_NULL_count]
FROM Sales.SalesOrderHeader;



-- Find a non-NULL value with an equality operator
DECLARE @SalesPersonID INT = 282;

SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID = @SalesPersonID;
GO



-- Can't use equality/inequality to find a NULL value
DECLARE @SalesPersonID INT = NULL;

-- NULL is not included in equality or inequality operator
SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID = @SalesPersonID;

SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID <> @SalesPersonID;
GO



-- So we have to write it a different way
DECLARE @SalesPersonID INT = NULL;

SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE ISNULL (SalesPersonID, -1) = ISNULL (@SalesPersonID, -1);
GO


-- Or to make the query SARGable...
-- This gets complex as more values are added to the criteria
DECLARE @SalesPersonID INT = NULL;

SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE (
	NOT (
		SalesPersonID <> @SalesPersonID
		OR SalesPersonID IS NULL
		OR @SalesPersonID IS NULL
	)
	OR (
		SalesPersonID IS NULL
		AND @SalesPersonID IS NULL
	)
);