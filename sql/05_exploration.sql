SELECT 'agency' AS TableName, COUNT(*) AS TotalRows
FROM nyc_311_database.agency
UNION ALL
SELECT 'problemcategory', COUNT(*)
FROM nyc_311_database.problemcategory
UNION ALL
SELECT 'location', COUNT(*)
FROM nyc_311_database.location
UNION ALL
SELECT 'servicerequest', COUNT(*)
FROM nyc_311_database.servicerequest;

SELECT MIN(CreatedDate) AS EarliestCreatedDate,
 MAX(CreatedDate) AS LatestCreatedDate,
 SUM(ClosedDate IS NULL) AS MissingClosedDate,
 SUM(ClosedDate < CreatedDate) AS ClosedBeforeCreated
FROM nyc_311_database.servicerequest;
SELECT YEAR(CreatedDate) AS RequestYear, COUNT(*) AS TotalRequests
FROM nyc_311_database.servicerequest
GROUP BY YEAR(CreatedDate) ORDER BY RequestYear;
-- Additional proposed analysis; output not yet recorded.
SELECT a.AgencyCode,a.AgencyName,COUNT(*) AS TotalRequests
FROM nyc_311_database.servicerequest s
JOIN nyc_311_database.agency a ON s.AgencyCode=a.AgencyCode
GROUP BY a.AgencyCode,a.AgencyName ORDER BY TotalRequests DESC,a.AgencyCode;
-- For duration analysis, exclude NULL and negative durations explicitly.
