-- ************************************************************************ --
-- SQL Server 2022 JSON: JSON_PATH_EXISTS
--
-- What it does: 
--    Tests whether a specified SQL/JSON path exists in the input JSON string.
--
-- SYNTAX:
--    JSON_PATH_EXISTS( value_expression, sql_json_path )  
--
-- New to SQL Server 2022: Entirely new function
-- Required Compatibility Level: N/A
--
-- Documentation: 
--    JSON_OBJECT: https://docs.microsoft.com/en-us/sql/t-sql/functions/json-object-transact-sql?view=sql-server-ver16
--    JSON_ARRAY: https://docs.microsoft.com/en-us/sql/t-sql/functions/json-array-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

USE AdventureWorks2019
GO

-- Example 1: Test various paths
DECLARE @jsonInfo NVARCHAR(MAX) = N'{"info":{"address":[{"town":"Paris"},{"town":"London"}]}}';

SELECT @jsonInfo AS [json_info]
	, JSON_PATH_EXISTS(@jsonInfo,'$.info.address') AS [$.info.address exists]
	, JSON_PATH_EXISTS(@jsonInfo,'$.info.town') AS [$.info.town exists]
	, JSON_PATH_EXISTS(@jsonInfo,'$.info.address[0].town') AS '$.info.address[0].town exists';




-- Example 2: Using ISJSON and JSON_PATH_EXISTS as a check constraint 
-- to enforce that only JSON Objects with a specific path can be stored in a column
DROP TABLE IF EXISTS dbo.new_orders;

CREATE TABLE dbo.new_orders (
	order_id int IDENTITY NOT NULL PRIMARY KEY,
	order_details nvarchar(4000) NOT NULL CHECK (
		(ISJSON(order_details, OBJECT) = 1) AND
		JSON_PATH_EXISTS(order_details, '$.OrderNumber') = 1
	)
);

DECLARE @json nvarchar(1000) = N'
{
    "OrderNumber": "S043659",
    "Date":"2022-05-24T08:01:00",
    "AccountNumber":"AW29825",
    "Price":59.99,
    "Quantity":1
}';

-- This will work
INSERT INTO dbo.new_orders (order_details) VALUES (@json);

SELECT * FROM dbo.new_orders;

-- This will throw an error
INSERT INTO dbo.new_orders (order_details) VALUES (N'{Orders:[{"OrderNumber": "S043659"},{"OrderNumber": "S043661"}]}');
