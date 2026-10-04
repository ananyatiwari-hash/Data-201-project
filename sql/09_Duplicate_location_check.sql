USE nyc_311_database;

-- Check for duplicate location combinations.

SELECT
    IncidentAddress,
    City,
    Borough,
    IncidentZip,
    Latitude,
    Longitude,
    COUNT(*) AS DuplicateCount
FROM location
GROUP BY
    IncidentAddress,
    City,
    Borough,
    IncidentZip,
    Latitude,
    Longitude
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC
LIMIT 10;