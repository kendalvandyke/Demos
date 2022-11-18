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
	, SensorReading NUMERIC(9, 6)
	, PressureReading NUMERIC(9, 6)
);
GO

INSERT INTO MachineTelemetry
(
       [timestamp]
       , SensorReading
)
VALUES
('2020-09-07 06:14:00.000', NULL)
, ('2020-09-07 06:14:15.000', 164.990400)
, ('2020-09-07 06:14:30.000', 162.241300)
, ('2020-09-07 06:14:45.000', 163.271200)
, ('2020-09-07 06:15:00.000', 161.368100)
, ('2020-09-07 06:15:15.000', NULL)
, ('2020-09-07 06:15:30.000', 162.213500)
, ('2020-09-07 06:15:45.000', NULL)
, ('2020-09-07 06:16:00.000', 157.695700)
, ('2020-09-07 06:16:15.000', 157.019200)
, ('2020-09-07 06:16:30.000', NULL)
, ('2020-09-07 06:16:45.000', 159.183500)


SELECT [timestamp]
       , SensorReading
FROM MachineTelemetry
ORDER BY [timestamp]



-- Example 1: Using FIRST_VALUE with IGNORE NULLS and RESPECT NULLS
-- This example partitions 

SELECT [timestamp]
	   , DATE_BUCKET(MINUTE, 1, [timestamp]) AS [timestamp_bucket]
	   , SensorReading
	   , FIRST_VALUE (SensorReading) IGNORE NULLS OVER win AS [IGNORE NULLS]
	   , FIRST_VALUE (SensorReading) RESPECT NULLS OVER win AS [RESPECT NULLS]	-- RESPECT_NULLS is the default
	   , FIRST_VALUE (SensorReading) OVER win AS [DEFAULT]
FROM MachineTelemetry
WINDOW win AS ( 
	PARTITION BY DATE_BUCKET(MINUTE, 1, [timestamp]) 
	ORDER BY [timestamp] 
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
ORDER BY [timestamp];


-- Example 2: Using LAST_VALUE with IGNORE NULLS and RESPECT NULLS

SELECT [timestamp]
	   , DATE_BUCKET(MINUTE, 1, [timestamp]) AS [timestamp_bucket]
	   , SensorReading
	   , LAST_VALUE (SensorReading) IGNORE NULLS OVER win AS [IGNORE NULLS]
	   , LAST_VALUE (SensorReading) RESPECT NULLS OVER win AS [RESPECT NULLS]	-- RESPECT_NULLS is the default
	   , LAST_VALUE (SensorReading) OVER win AS [DEFAULT]
FROM MachineTelemetry
WINDOW win AS ( 
	PARTITION BY DATE_BUCKET(MINUTE, 1, [timestamp]) 
	ORDER BY [timestamp] 
	ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
ORDER BY [timestamp];