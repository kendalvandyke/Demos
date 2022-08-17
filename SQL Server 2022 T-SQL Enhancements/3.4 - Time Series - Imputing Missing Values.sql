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
('2020-09-07 06:14:51.000', 164.990400, 7.223600)
, ('2020-09-07 06:14:52.000', 162.241300, 93.992800)
, ('2020-09-07 06:14:52.090', NULL, 93.1)	-- Note the extra PressureReading value in this second
, ('2020-09-07 06:14:53.000', 163.271200, NULL)
, ('2020-09-07 06:14:54.000', 161.368100, 93.403700)
, ('2020-09-07 06:14:55.000', NULL, NULL)
, ('2020-09-07 06:14:55.090', 162.368100, 93.1) -- Another extra reading during this second
, ('2020-09-07 06:14:56.000', NULL, 98.364800)
, ('2020-09-07 06:14:59.000', NULL, 94.098300)
, ('2020-09-07 06:15:01.000', 157.695700, 103.359100)
, ('2020-09-07 06:15:02.000', 157.019200, NULL)
, ('2020-09-07 06:15:04.000', NULL, 95.352000)
, ('2020-09-07 06:15:06.000', 159.183500, 100.748200);


--- Gap Filling -> Creating a contingous, ordered set of timestamps within a datetime range.
SET NOCOUNT ON

CREATE TABLE #SeriesGenerate (
	dt DATETIME PRIMARY KEY CLUSTERED
);
GO
DECLARE @startdate datetime
	, @endtime datetime;

SELECT @startdate =   CAST(FORMAT(MIN([timestamp]), 'MM/dd/yyyy HH:mm:ss') AS datetime)
	, @endtime = CAST(FORMAT(MAX([timestamp]), 'MM/dd/yyyy HH:mm:ss') AS datetime)
FROM MachineTelemetry;

WHILE (@startdate <= @endtime)
BEGIN
	INSERT INTO #SeriesGenerate
	VALUES
	(@startdate);
	SET @startdate = DATEADD (SECOND, 1, @startdate);
END;

SELECT *
INTO #GapFilledTable
FROM (
	SELECT ISNULL(b.[timestamp], a.dt) AS [timestamp]
		, b.VoltageReading
		, b.PressureReading
	FROM #SeriesGenerate a
		LEFT OUTER JOIN MachineTelemetry b ON a.dt = CAST(FORMAT(b.[timestamp], 'MM/dd/yyyy HH:mm:ss') AS datetime)
) a;


-- Look at contents of the gap filled version of MachineTelemetry
SELECT *
FROM #GapFilledTable;


-- Use the gap filled version of MachineTelemetry to return imputed values
-- Using IGNORE NULLS so that we get a value for timestamps that had NULL values
Select 
    [timestamp], 
    VoltageReading As OrigVoltageVals,
    LAST_VALUE(VoltageReading) IGNORE NULLS OVER (ORDER BY timestamp) As ImputedVoltageLastValue,
    PressureReading As OrigPressureVals,
    LAST_VALUE(PressureReading) IGNORE NULLS OVER (ORDER BY timestamp) As ImputedPressureLastValue
From 
#GapFilledTable
order by [timestamp];




-- Now do the same thing with time series functions in a single query
-- Bonus: change bucket sizes dynamically 
-- Start with a bucket of 1, change to 5
DECLARE @SecondsPerBucket INT = 5;

WITH cteTimeSeries AS (
	SELECT DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp)) AS min_timestamp,
		DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp)) AS max_timestamp,
		DATEDIFF(second, DATE_BUCKET(SECOND, @SecondsPerBucket, MIN(timestamp)), DATE_BUCKET(SECOND, @SecondsPerBucket, MAX(timestamp))) AS seconds_to_generate
	FROM MachineTelemetry
)
, cteGapFilledSeries AS (
	SELECT DATEADD(second, s.value, ts.min_timestamp) AS [timestamp]
	FROM cteTimeSeries AS ts
		 CROSS APPLY GENERATE_SERIES(0, ts.seconds_to_generate, @SecondsPerBucket) AS s
)
, cteMachineTelemetry AS (
	SELECT DISTINCT
		DATE_BUCKET(SECOND, @SecondsPerBucket, [timestamp]) AS [timestamp]
		, LAST_VALUE(VoltageReading) IGNORE NULLS OVER (
				PARTITION BY DATE_BUCKET(SECOND, @SecondsPerBucket, [timestamp]) 
				ORDER BY [timestamp] 
				ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			) AS [VoltageReading]
		, LAST_VALUE(PressureReading) IGNORE NULLS OVER (
				PARTITION BY DATE_BUCKET(SECOND, @SecondsPerBucket, [timestamp]) 
				ORDER BY [timestamp] 
				ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			) AS [PressureReading]
	FROM MachineTelemetry
)
SELECT 
    ts.timestamp AS [Timestamp],
    t.VoltageReading As [Original Voltage],
    LAST_VALUE(t.VoltageReading) IGNORE NULLS OVER (ORDER BY ts.timestamp) As [Imputed Voltage], 
    t.PressureReading As [Original Pressure],
    LAST_VALUE(t.PressureReading) IGNORE NULLS OVER (ORDER BY ts.timestamp) As [Imputed Pressure]
FROM cteGapFilledSeries AS ts
	LEFT OUTER JOIN cteMachineTelemetry AS t ON ts.timestamp = t.timestamp
ORDER BY ts.timestamp;



-- Cleanup
DROP TABLE IF EXISTS #SeriesGenerate;
DROP TABLE IF EXISTS #GapFilledTable;
