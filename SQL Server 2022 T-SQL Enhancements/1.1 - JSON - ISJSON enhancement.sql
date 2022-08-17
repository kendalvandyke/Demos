-- ************************************************************************ --
-- SQL Server 2022 JSON: ISJSON enhancement
--
-- What it does: 
--    Tests whether a string contains valid JSON according to IETF RFC 4627 or RFC 8259
--    This is currently available in SQL 2016
--
-- SYNTAX: 
--    ISJSON ( expression [, json_type_constraint ] )
-- 
--      json_type_constraint can be one of the following:
--        VALUE		Tests for a valid JSON value. This can be a JSON object, array, number, 
--                  string or one of the three literal values (false, true, null)
--        OBJECT	Tests for a valid JSON object (This is the default if not specified)
--        ARRAY		Tests for a valid JSON array
--        SCALAR	Tests for a valid JSON scalar (number or string)
--
-- NOTES:
--    ISJSON without json_type_constraint tests for documents that conform to RFC 4627 (object or array)
--    ISJSON with json_type_constraint tests for documents that conform to RFC 8259
--
--
-- New to SQL Server 2022: json_type_constraint argument
-- Required Compatibility Level: N/A
--
-- Documentation: https://docs.microsoft.com/en-us/sql/t-sql/functions/isjson-transact-sql?view=sql-server-ver16
-- More information: https://techcommunity.microsoft.com/t5/azure-sql-blog/announcing-json-enhancements-in-azure-sql-database-azure-sql/ba-p/3417071
-- ************************************************************************ --

-- Example 1: Test various JSON strings for type validity 
SELECT T.doc AS [test_value]
	   , ISJSON (T.doc) AS is_json_rfc_4627
	   , ISJSON (T.doc, VALUE) AS is_json_value
	   , ISJSON (T.doc, OBJECT) AS is_json_object
	   , ISJSON (T.doc, ARRAY) AS is_json_array
	   , ISJSON (T.doc, SCALAR) AS is_j2son_scalar
FROM (
	VALUES ('abc')
		   , ('''abc''')
		   , ('"test string"')
		   , ('1.0')
		   , ('1.0')
		   , ('1')
		   , ('1E2')
		   , ('false')
		   , ('true')
		   , ('TRUE')
		   , ('"false"')
		   , ('null')
		   , ('Null')
		   , ('NULL')
		   , (N'{"info":{"address":[{"town":"Paris"},{"town":"London"}]}}')
		   , (N'[{"town":"Paris"},{"town":"London"}]')
) AS T (doc);