USE nyc_311_database;

-- A2: Agencies with above-average request volumes.
-- Techniques: Subquery, JOIN, GROUP BY, HAVING.

SELECT
    a.AgencyCode,
    a.AgencyName,
    COUNT(*) AS TotalRequests
FROM agency AS a
JOIN servicerequest AS s
    ON a.AgencyCode = s.AgencyCode
GROUP BY
    a.AgencyCode,
    a.AgencyName
HAVING COUNT(*) > (
    SELECT AVG(AgencyTotal)
    FROM (
        SELECT COUNT(*) AS AgencyTotal
        FROM servicerequest
        GROUP BY AgencyCode
    ) AS AgencyCounts
)
ORDER BY TotalRequests DESC;