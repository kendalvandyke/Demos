-- ************************************************************************ --
-- SQL Server 2022 JSON: JSON_OBJECT and JSON_ARRAY
--
-- What it does: 
--    JSON_OBJECT: Constructs JSON object text from zero or more expressions.
--    JSON_ARRAY: Constructs JSON array text from zero or more expressions.
--
-- SYNTAX:
--    JSON_OBJECT ( [ json_key_name : value_expression [,...n] ] [ NULL ON NULL | ABSENT ON NULL ] )
--    JSON_ARRAY ( [ value_expression [,...n] ] [ NULL ON NULL | ABSENT ON NULL ]  )
--
-- New to SQL Server 2022: Entirely new functions
-- Required Compatibility Level: N/A
--
-- Documentation: 
--    JSON_OBJECT: https://docs.microsoft.com/en-us/sql/t-sql/functions/json-object-transact-sql?view=sql-server-ver16
--    JSON_ARRAY: https://docs.microsoft.com/en-us/sql/t-sql/functions/json-array-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

USE AdventureWorks2019
GO

-- Example 1: Using JSON_OBJECT
DECLARE @KeyVal VARCHAR(50)=  'OrderDate';

SELECT JSON_OBJECT('OrderNum':43659, @KeyVal:'2011-05-31', 'CurrentDate':GETDATE()) AS [JSON_OBJECT];


-- Example 2: Using JSON_ARRAY
DECLARE @ArrayVal VARCHAR(10) = 'yellow';

SELECT JSON_ARRAY('red', 'orange', @ArrayVal, 'green', 'blue', 'indigo', 'violet') AS [JSON_ARRAY];




-- Example 3: Handling NULL values in JSON_OBJECT
-- NULL ON NULL:  converts the SQL NULL value into a JSON null value when generating the JSON key value
-- ABSENT ON NULL: omit the entire key if the value is NULL

SELECT N'JSON_OBJECT' AS [function]
	, JSON_OBJECT('OrderNum':43659, 'ShipDate':NULL) AS [default_behavior]
	, JSON_OBJECT('OrderNum':43659, 'ShipDate':NULL ABSENT ON NULL) AS [absent_on_null]
	, JSON_OBJECT('OrderNum':43659, 'ShipDate':NULL NULL ON NULL) AS [null_on_null]

SELECT N'JSON_ARRAY' AS [function]
	, JSON_ARRAY('red', NULL, 'orange') AS [default_behavior]
	, JSON_ARRAY('red', NULL, 'orange' ABSENT ON NULL) AS [absent_on_null]
	, JSON_ARRAY('red', NULL, 'orange' NULL ON NULL) AS [null_on_null];





-- Example 4: Using JSON_OBJECT & JSON_ARRAY together to create complex nested JSON
SELECT JSON_OBJECT(
	'Program':'Apollo'
	, 'Vehicles':JSON_OBJECT(
		'Vehicle':JSON_OBJECT(
			'Name':'Saturn I'
			, 'Missions':JSON_ARRAY('SA-1','SA-2','SA-3','SA-4','SA-5','AS-101','AS-102','AS-103','AS-104','AS-105')
		)
		, 'Vehicle':JSON_OBJECT(
			'Name':'Saturn IB'
			, 'Missions':JSON_ARRAY('AS-201','AS-203','AS-202','Apollo 1','Apollo 5','Apollo 7')
		)
		, 'Vehicle':JSON_OBJECT(
			'Name':'Saturn V'
			, 'Missions':JSON_ARRAY(
				'Apollo 8','Apollo 9','Apollo 10','Apollo 11','Apollo 12','Apollo 13'
				, 'Apollo 14','Apollo 15','Apollo 16','Apollo 17'
			)
		)
	)
);




-- Example 5: Comparing JSON_OBJECT + JSON_ARRAY with FOR JSON
-- Using JSON_OBJECT & JSON_ARRAY
SELECT TOP 5 
	a.AddressID
	, JSON_OBJECT(
		'Address':JSON_OBJECT (
			'AddressLine1':a.AddressLine1
			, 'AddressLine2':a.AddressLine2
			, 'City':a.City
			, 'PostalCode':a.PostalCode
			, 'LatLong':JSON_ARRAY(
					CAST(SpatialLocation.Lat AS DECIMAL(8,5))
					, CAST(SpatialLocation.Long AS DECIMAL(8,5))
				)
			NULL ON NULL
		)
	) AS [json_info]
FROM Person.[Address] AS a
ORDER BY a.AddressID


-- ... same result using FOR JSON PATH
SELECT TOP 5
	a.AddressID
	, (
		SELECT a.AddressLine1 AS 'Address.AddressLine1'
			, a.AddressLine2 AS 'Address.AddressLine2'
			, a.City AS 'Address.City'
			, a.PostalCode AS 'Address.PostalCode'
			, JSON_QUERY(
				CONCAT(
					'[', 
					CONCAT_WS(
						',' 
						, QUOTENAME(CAST(SpatialLocation.Lat AS DECIMAL(8,5)), '"')
						, QUOTENAME(CAST(SpatialLocation.Long AS DECIMAL(8,5)), '"')
					),
					']'
				) 
			) AS 'Address.LatLong'
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES 
	)
FROM Person.[Address] AS a
ORDER BY a.AddressID;