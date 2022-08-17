-- ************************************************************************ --
-- SQL Server 2022 New T-SQL Features: STRING_SPLIT enhancement
--
-- What it does:
--    Table-valued function that splits a string into rows of substrings, based on a specified separator character
--
-- SYNTAX: 
--    STRING_SPLIT ( string , separator [ , enable_ordinal ] )  
--
-- New to SQL Server 2022: enable_ordinal argument
-- Required Compatibility Level: 130
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

USE AdventureWorks2019;
GO

-- Example 1: Parse a comma-separated list of values
-- STRING_SPLIT will return empty string if there is nothing between separator. 

DECLARE @tags NVARCHAR(400) = N'clothing,road,,touring,bike'  
  
SELECT value, ordinal  
FROM STRING_SPLIT(@tags, ',', 1);



-- Example 2: Find all rows with an even ordinal value

SELECT *
FROM STRING_SPLIT('Austin,Texas,Seattle,Washington,Denver,Colorado', ',', 1)
WHERE ordinal % 2 = 0
ORDER BY ordinal;