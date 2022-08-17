-- ************************************************************************ --
-- SQL Server 2022 Time Series: DATE_BUCKET
--
-- What it does:
--    Returns the datetime value corresponding to the start of each datetime bucket, from the timestamp defined by 
--    the origin parameter or the default origin value of 1900-01-01 00:00:00.000 if the origin parameter is not specified.
--
-- SYNTAX: 
--    DATE_BUCKET (datepart, number, date [, origin ] )
--
-- New to SQL Server 2022: Entirely new function
-- Required Compatibility Level: N/A
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/functions/date-bucket-transact-sql?view=sql-server-ver16
-- ************************************************************************ --


-- Example 1: Calculate DATE_BUCKET with a bucket width of 1 from the origin time

DECLARE @date DATETIME = GETDATE();

SELECT 'Now' AS [BucketName], @date AS [DateBucketValue], @date AS [DateTruncValue]
UNION ALL
SELECT 'Year', DATE_BUCKET (YEAR, 1, @date), DATETRUNC (YEAR, @date)
UNION ALL
SELECT 'Quarter', DATE_BUCKET (QUARTER, 1, @date), DATETRUNC (QUARTER, @date)
UNION ALL
SELECT 'Month', DATE_BUCKET (MONTH, 1, @date), DATETRUNC (MONTH, @date)
UNION ALL
SELECT 'Week', DATE_BUCKET (WEEK, 1, @date), DATETRUNC (WEEK, @date)
UNION ALL
SELECT 'Day', DATE_BUCKET (DAY, 1, @date), DATETRUNC (DAY, @date)
UNION ALL
SELECT 'Hour', DATE_BUCKET (HOUR, 1, @date), DATETRUNC (HOUR, @date)
UNION ALL
SELECT 'Minutes', DATE_BUCKET (MINUTE, 1, @date), DATETRUNC (MINUTE, @date)
UNION ALL
SELECT 'Seconds', DATE_BUCKET (SECOND, 1, @date), DATETRUNC (SECOND, @date);



-- Example 2: Use a known origin value for WEEK datepart to start at Sunday
-- The default origin (1900-01-01 00:00:00.000) is a Monday,
-- so watch out when using DATE_BUCKET to find the beginning of the week

DECLARE @known_origin DATETIME  = '1900-01-07 00:00:00';

SELECT  @known_origin AS [KnownOrigin]
	   , DATENAME (WEEKDAY, @known_origin) AS [KnownOriginDay]
	   , DATE_BUCKET (WEEK, 1, GETDATE (), @known_origin) AS [DateBucketKnownOrigin]
	   , DATENAME (WEEKDAY, DATE_BUCKET (WEEK, 1, GETDATE (), @known_origin)) AS [DateBucketKnownOriginDay];


-- Example 3: Using DATE_BUCKET for arbitrary bucket sizes

-- DATE_BUCKET is more capable than DATETRUNC when we need arbitrary bucket sizes
-- e.g. determining 5 minute or quarter hour buckets

SELECT 'Now' AS [BucketName], GETDATE() AS [BucketDate]
UNION ALL
SELECT '5 Minute Buckets', DATE_BUCKET (MINUTE, 5, GETDATE())
UNION ALL
SELECT 'Quarter Hour', DATE_BUCKET (MINUTE, 15, GETDATE());
