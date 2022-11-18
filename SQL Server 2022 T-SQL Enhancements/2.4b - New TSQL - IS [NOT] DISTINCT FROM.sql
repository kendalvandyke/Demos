-- ************************************************************************ --
-- SQL Server 2022 New T-SQL Features: IS [NOT] DISTINCT FROM
--
-- What it does:
--    Compares the equality of two expressions and guarantees a true or false result, even if one or both operands are NULL.
--
-- SYNTAX: 
--    expression IS [NOT] DISTINCT FROM expression
--
-- New to SQL Server 2022: Entirely new predicate
-- Required Compatibility Level: N/A
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/queries/is-distinct-from-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

/*
IS [NOT] DISTINCT FROM is a predicate used in the search condition of WHERE clauses and HAVING clauses, 
the join conditions of FROM clauses, and other constructs where a Boolean value is required.

Comparing a NULL value to any other value, including another NULL, will have an unknown result. 
IS [NOT] DISTINCT FROM will always return true or false, as it will treat NULL values as known values when used as a comparison operator.

+=======+=======+==========+===========================+
| A     | B     | A = B    | A IS NOT DISTINCT FROM B  |
+=======+=======+==========+===========================+
| 0     | 0     | True     | True                      |
| 0     | 1     | False    | False                     |
| 0     | NULL  | Unknown  | False                     |
| NULL  | NULL  | Unknown  | True                      |
+-------+-------+----------+---------------------------+

A IS DISTINCT FROM B will decode to: ((A <> B OR A IS NULL OR B IS NULL) AND NOT (A IS NULL AND B IS NULL))
A IS NOT DISTINCT FROM B will decode to: (NOT (A <> B OR A IS NULL OR B IS NULL) OR (A IS NULL AND B IS NULL))

*/


-- Setup
USE AdventureWorks2019
GO
SET NOCOUNT ON
GO
DROP TABLE IF EXISTS #SampleTempTable;
GO
CREATE TABLE #SampleTempTable (id INT, message nvarchar(50));
INSERT INTO #SampleTempTable VALUES (null, 'hello') ;
INSERT INTO #SampleTempTable VALUES (10, null);
INSERT INTO #SampleTempTable VALUES (17, 'abc');
INSERT INTO #SampleTempTable VALUES (17, 'yes');
INSERT INTO #SampleTempTable VALUES (null, null);
GO




-- Example 1: Use IS DISTINCT FROM
-- Equivalent to: WHERE ( id <> 17 OR id IS NULL OR 17 IS NULL) AND NOT ( id IS NULL AND 17 IS NULL )

SELECT *
	, 'WHERE id IS DISTINCT FROM 17' AS [Comparison] 
FROM #SampleTempTable 
WHERE id IS DISTINCT FROM 17;

-- Example 2: Use IS NOT DISTINCT FROM
-- Equivalent to: WHERE (NOT (id <> 17 OR id IS NULL OR 17 IS NULL) OR (id IS NULL AND 17 IS NULL))

SELECT *, 'WHERE id IS NOT DISTINCT FROM 17' AS [Comparison] 
FROM #SampleTempTable 
WHERE id IS NOT DISTINCT FROM 17;


-- Example 3: Use IS DISTINCT FROM against a NULL value
-- Equivalent to: WHERE ( id <> NULL OR id IS NULL OR NULL IS NULL) AND NOT ( id IS NULL AND NULL IS NULL )

SELECT *, 'WHERE id IS DISTINCT FROM NULL' AS [Comparison] 
FROM #SampleTempTable 
WHERE id IS DISTINCT FROM NULL;


-- Example 4: Use IS NOT DISTINCT FROM against a NULL value
-- Equivalent to: WHERE (NOT (id <> NULL OR id IS NULL OR NULL IS NULL) OR (id IS NULL AND NULL IS NULL))

SELECT * , 'WHERE id IS NOT DISTINCT FROM NULL' AS [Comparison] 
FROM #SampleTempTable 
WHERE id IS NOT DISTINCT FROM NULL;





-- Example 5: IS NOT DISTINCT FROM as a replacement for equality

-- BEFORE
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
GO

-- AFTER
DECLARE @SalesPersonID INT = NULL;

SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT DISTINCT FROM @SalesPersonID;
GO

DECLARE @SalesPersonID INT = 282;

SELECT SalesOrderID, SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT DISTINCT FROM @SalesPersonID;
GO