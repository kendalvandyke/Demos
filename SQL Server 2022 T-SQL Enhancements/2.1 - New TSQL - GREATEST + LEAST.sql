-- ************************************************************************ --
-- SQL Server 2022 New T-SQL Features: GREATEST & LEAST
--
-- What it does: 
--    GREATEST: Returns the maximum value from a list of one or more expressions
--    LEAST: Returns the minimum value from a list of one or more expressions
--
-- SYNTAX: 
--    GREATEST ( expression1 [ ,...expressionN ] )
--    LEAST ( expression1 [ ,...expressionN ] )
--
-- New to SQL Server 2022: Entirely new functions
-- Required Compatibility Level: N/A
--
-- Documentation: 
--    GREATEST: https://docs.microsoft.com/en-us/sql/t-sql/functions/logical-functions-greatest-transact-sql
--       LEAST: https://docs.microsoft.com/en-us/sql/t-sql/functions/logical-functions-least-transact-sql
-- ************************************************************************ --

USE AdventureWorks2019; 
GO 

-- Example 1: Return max/min value from a list of constraints
-- The scale of the return type is determined by the scale of the argument with the highest precedence data type.
-- NULL values are ignored

DECLARE @Compare NVARCHAR(5) = N'7';

SELECT GREATEST('6.62', 3.1415, NULL, @Compare) AS GreatestVal
	, LEAST('6.62', 3.1415, NULL, @Compare) AS LeastVal;
GO 
EXECUTE sp_describe_first_result_set @tsql=N'SELECT GREATEST(''6.62'', 3.1415, NULL, N''7'')';
EXECUTE sp_describe_first_result_set @tsql=N'SELECT LEAST(''6.62'', 3.1415, NULL, N''7'')';
GO



-- Example 2: Return max/min value from a list of character types
-- The following example returns the maximum value from the list of character constants that is provided.

SELECT GREATEST('Glacier', N'Joshua Tree', 'Mount Rainier') AS GreatestString
	, LEAST ('Glacier', N'Joshua Tree', 'Mount Rainier') AS LeastString;
GO 
EXECUTE sp_describe_first_result_set @tsql=N'SELECT GREATEST(''Glacier'', N''Joshua Tree'', ''Mount Rainier'')';
EXECUTE sp_describe_first_result_set @tsql=N'SELECT LEAST(''Glacier'', N''Joshua Tree'', ''Mount Rainier'')';
GO



-- Example 3: An error is thrown when data types cannot be converted for comparison
SELECT GREATEST('6.62', 3.1415, N'Mount Rainier') AS GreatestVal
	, LEAST('6.62', 3.1415, N'Mount Rainier') AS LeastVal;
GO 



-- Example 4: Return max/min value from a list of column arguments

SELECT sp.SalesQuota, sp.SalesYTD, sp.SalesLastYear 
      , GREATEST(sp.SalesQuota, sp.SalesYTD, sp.SalesLastYear) AS SalesGreatest
	  , LEAST(sp.SalesQuota, sp.SalesYTD, sp.SalesLastYear) AS SalesLeast
FROM Sales.SalesPerson AS sp 
WHERE sp.SalesYTD < 3000000; 
GO