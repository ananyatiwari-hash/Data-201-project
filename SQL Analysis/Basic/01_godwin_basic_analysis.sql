USE nyc_311_database;

-- B1: Total service requests by borough
-- Technique: LEFT JOIN, GROUP BY, COUNT, ORDER BY

SELECT
    COALESCE(l.Borough, 'Unknown') AS Borough,
    COUNT(*) AS TotalRequests
FROM servicerequest AS s
LEFT JOIN location AS l
    ON s.LocationID = l.LocationID
GROUP BY
    COALESCE(l.Borough, 'Unknown')
ORDER BY
    TotalRequests DESC;