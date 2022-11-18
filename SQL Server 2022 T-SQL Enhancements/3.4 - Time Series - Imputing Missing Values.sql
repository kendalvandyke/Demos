-- ************************************************************************ --
-- SQL Server 2022 Time Series: Imputing Missing Values
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
);
GO
INSERT INTO MachineTelemetry
(
       [timestamp]
       , SensorReading
)
VALUES
('2020-09-07 06:14:51.000', 164.990400)
, ('2020-09-07 06:14:52.000', 162.241300)
, ('2020-09-07 06:14:52.090', 161.990400)	-- Note the extra reading in this second
, ('2020-09-07 06:14:53.000', 163.271200)
, ('2020-09-07 06:14:54.000', 161.368100)
, ('2020-09-07 06:14:55.000', 157.183500)
, ('2020-09-07 06:14:55.090', 162.368100)	-- Another extra reading during this second
, ('2020-09-07 06:14:56.000', 163.183500)
, ('2020-09-07 06:14:59.000', 162.990400)
, ('2020-09-07 06:15:01.000', 157.695700)
, ('2020-09-07 06:15:02.000', 157.019200)
, ('2020-09-07 06:15:04.000', 157.990400)
, ('2020-09-07 06:15:06.000', 159.183500);

SELECT [timestamp]
       , SensorReading
FROM MachineTelemetry
ORDER BY [timestamp];


-- Combine Time Series functions to return LAST_VALUE for each partition in arbitrary buckets

-- Step 1: Determine the min and max timestamps, 
-- and the number of seconds between min and max
-- using DATE_BUCKET to group timestamps into buckets
DECLARE @SecondsPerBucket INT = 1;

SELECT DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp)) AS min_timestamp,
	DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp)) AS max_timestamp,
	DATEDIFF(second
				, DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp))
				, DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp))
			) AS seconds_to_generate
FROM MachineTelemetry;
GO



-- Step 2: Use GENERATE_SERIES with DATEADD to create a contiguous 
-- series of timestamps between min and max buckets at stepped intervals
DECLARE @SecondsPerBucket INT = 1;

WITH cteStepOne AS (
	SELECT DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp)) AS min_timestamp,
		DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp)) AS max_timestamp,
		DATEDIFF(second
					, DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp))
					, DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp))
				) AS seconds_to_generate
	FROM MachineTelemetry
)
SELECT DATEADD(second, s.value, ts.min_timestamp) AS [timestamp]
FROM cteStepOne AS ts
		CROSS APPLY GENERATE_SERIES(0, ts.seconds_to_generate, @SecondsPerBucket) AS s
GO



-- Step 3: Use DATE_BUCKET and LAST_VALUE to determine the last
-- Measurement and Pressure reading from each bucket (partition)
-- Using ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING to
-- ensure we use the last read value from each bucket (partition)
DECLARE @SecondsPerBucket INT = 1;

SELECT DISTINCT
	DATE_BUCKET(SECOND, @SecondsPerBucket, [timestamp]) AS [timestamp]
	, LAST_VALUE(SensorReading) IGNORE NULLS OVER (
			PARTITION BY DATE_BUCKET(SECOND, @SecondsPerBucket, [timestamp]) 
			ORDER BY [timestamp] 
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) AS [SensorReading]
FROM MachineTelemetry;





-- Step 4: Put it all together to return a gap-filled table with imputed values
-- Bonus: change bucket sizes dynamically ... Start with a bucket of 1, change to 5
DECLARE @SecondsPerBucket INT = 5;

WITH cteStepOne AS (
	SELECT DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp)) AS min_timestamp,
		DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp)) AS max_timestamp,
		DATEDIFF(second
					, DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp))
					, DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp))
				) AS seconds_to_generate
	FROM MachineTelemetry
) 
, cteStepTwo AS (
	SELECT DATEADD(second, s.value, ts.min_timestamp) AS [timestamp]
	FROM cteStepOne AS ts
		 CROSS APPLY GENERATE_SERIES(0, ts.seconds_to_generate, @SecondsPerBucket) AS s
)
, cteStepThree AS (
	SELECT DISTINCT
		DATE_BUCKET(SECOND, @SecondsPerBucket, [timestamp]) AS [timestamp]
		, LAST_VALUE(SensorReading) IGNORE NULLS OVER (
				PARTITION BY DATE_BUCKET(SECOND, @SecondsPerBucket, [timestamp]) 
				ORDER BY [timestamp] 
				ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			) AS [SensorReading]
	FROM MachineTelemetry
)
SELECT 
    ts.timestamp AS [Timestamp]
	, t.SensorReading As [Original Measurement]
	, LAST_VALUE(t.SensorReading) IGNORE NULLS OVER (ORDER BY ts.timestamp) As [Imputed Measurement]
FROM cteStepTwo AS ts
	LEFT OUTER JOIN cteStepThree AS t ON ts.timestamp = t.timestamp
ORDER BY ts.timestamp;