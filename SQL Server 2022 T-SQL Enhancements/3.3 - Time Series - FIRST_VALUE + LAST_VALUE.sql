-- ************************************************************************ --
-- SQL Server 2022 Time Series: FIRST_VALUE and LAST_VALUE enhancement
--
-- What it does:
--    Returns the first/last value in an ordered set of values.
--
-- SYNTAX: 
--    FIRST_VALUE ( [scalar_expression ] )  [ IGNORE NULLS | RESPECT NULLS ]
--        OVER ( [ partition_by_clause ] order_by_clause [ rows_range_clause ] )
--
--    LAST_VALUE ( [ scalar_expression ] )  [ IGNORE NULLS | RESPECT NULLS ]
--        OVER ( [ partition_by_clause ] order_by_clause rows_range_clause )
--
-- New to SQL Server 2022:
--    IGNORE NULLS - Ignore null values in the dataset when computing the first/last value over a partition.
--    RESPECT NULLS - Respect null values in the dataset when computing first/last value over a partition.
--
-- Required Compatibility Level: N/A
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/functions/generate-series-transact-sql?view=sql-server-ver16
-- ************************************************************************ --

-- Setup
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'GapFilling')
BEGIN
	CREATE DATABASE GapFilling;
END;
GO

USE GapFilling;
GO
DROP TABLE IF EXISTS MachineTelemetry;
GO
CREATE TABLE MachineTelemetry (
	timestamp DATETIME
	, VoltageReading NUMERIC(9, 6)
	, PressureReading NUMERIC(9, 6)
);
GO

INSERT INTO MachineTelemetry
(
       [timestamp]
       , VoltageReading
       , PressureReading
)
VALUES
('2020-09-07 06:14:50.000', NULL, NULL)
, ('2020-09-07 06:14:51.000', 164.990400, 7.223600)
, ('2020-09-07 06:14:52.000', 162.241300, 93.992800)
, ('2020-09-07 06:14:53.000', 163.271200, NULL)
, ('2020-09-07 06:14:54.000', 161.368100, 93.403700)
, ('2020-09-07 06:14:55.000', NULL, NULL)
, ('2020-09-07 06:14:56.000', NULL, 98.364800)
, ('2020-09-07 06:14:59.000', NULL, 94.098300)
, ('2020-09-07 06:15:01.000', 157.695700, 103.359100)
, ('2020-09-07 06:15:02.000', 157.019200, NULL)
, ('2020-09-07 06:15:04.000', NULL, 95.352000)
, ('2020-09-07 06:15:06.000', 159.183500, 100.748200);



-- Example 1: Using FIRST_VALUE and show the difference between IGNORE NULLS and RESPECT NULLS

-- RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING is required for the correct values to be returned
-- (The default is RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW, which would return the first value from the entire result set)
SELECT [timestamp]
	   , VoltageReading
	   , FIRST_VALUE (VoltageReading) IGNORE NULLS OVER (ORDER BY timestamp) AS [FIRST_VALUE IGNORE NULLS]
	   , FIRST_VALUE (VoltageReading) RESPECT NULLS OVER (ORDER BY timestamp) AS [FIRST_VALUE RESPECT NULLS]	-- RESPECT_NULLS is the default

	   , FIRST_VALUE (VoltageReading) IGNORE NULLS OVER (
				ORDER BY timestamp ASC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW 
			) AS [Default]

	   , [timestamp] AS [timestamp 2]
	   , VoltageReading
	   , FIRST_VALUE (VoltageReading) IGNORE NULLS OVER (
				ORDER BY timestamp ASC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING 
			) AS [FIRST_VALUE IGNORE NULLS UNBOUNDED]
	   , FIRST_VALUE (VoltageReading) RESPECT NULLS OVER (
				ORDER BY timestamp ASC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING 
			) AS [FIRST_VALUE RESPECT NULLS UNBOUNDED]
FROM MachineTelemetry
ORDER BY [timestamp];


-- Example 2: Using LAST_VALUE 
-- No ROWS/RANGE needed in this case (shown below to demonstrate the default behavior)
SELECT timestamp
	   , VoltageReading
		, LAST_VALUE (VoltageReading) IGNORE NULLS OVER (
				ORDER BY timestamp ASC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW 
			) AS [LAST_VALUE Default]
	   , LAST_VALUE (VoltageReading) IGNORE NULLS OVER (ORDER BY timestamp) AS [LAST_VALUE IGNORE NULLS]
	   , LAST_VALUE (VoltageReading) RESPECT NULLS OVER (ORDER BY timestamp) AS [LAST_VALUE RESPECT NULLS]
FROM MachineTelemetry
ORDER BY [timestamp];

