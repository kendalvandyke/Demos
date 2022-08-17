-- ************************************************************************ --
-- SQL Server 2022 Time Series: GENERATE_SERIES
--
-- What it does:
--    Generates a series of numbers within a given interval. 
--    The interval and the step between series values are defined by the user.
--
-- SYNTAX: 
--    GENERATE_SERIES ( start, stop [, step ] )
--
-- New to SQL Server 2022: Entirely new functions
-- Required Compatibility Level: 160
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/functions/generate-series-transact-sql?view=sql-server-ver16
-- ************************************************************************ --


USE AdventureWorks2019
GO

/*
The GENERATE_SERIES clause functionality is available only under compatibility level 160 or higher. 
*/
ALTER DATABASE [AdventureWorks2019] SET COMPATIBILITY_LEVEL =  160


-- Example 1: Generate a series of integer values between 1 and 10 in increments of 1 (defualt)
SELECT value
FROM GENERATE_SERIES(1, 10);


-- Example 2: Generate a series of integer values between 100 and 1 in increments of -5
SELECT value
FROM GENERATE_SERIES(100, 1, -5);


-- Example 3: Generate a series of decimal values between 0 and 1.0 in increments of 0.05
SELECT value
FROM GENERATE_SERIES(0.0, 1.0, 0.05);


-- Example 4: Empty result set from a positive range and a negative step
SELECT value
FROM GENERATE_SERIES(1, 10, -5);



-- Example 4: Data types must match! This results in an error
DECLARE @start INT = 1;
DECLARE @stop INT = 1;
DECLARE @step decimal(2,1) = 0.5;

SELECT value
FROM GENERATE_SERIES(@start, @stop, @step);


-- If omitted, STEP will default to the same datatype as START and STOP
SELECT value
FROM GENERATE_SERIES(1.0, 10.0);
