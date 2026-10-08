USE nyc_311_database;

-- B2: Average hours to close a request, by agency.
-- Techniques: JOIN, WHERE, AVG, GROUP BY, HAVING.

SELECT
    a.AgencyCode,
    a.AgencyName,
    COUNT(*) AS ClosedRequests,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, s.CreatedDate, s.ClosedDate)) / 60, 1)
        AS AvgHoursToClose,
    ROUND(MAX(TIMESTAMPDIFF(MINUTE, s.CreatedDate, s.ClosedDate)) / 60 / 24, 1)
        AS MaxDaysToClose
FROM servicerequest AS s
INNER JOIN agency AS a
    ON s.AgencyCode = a.AgencyCode
WHERE s.ClosedDate IS NOT NULL
  AND s.ClosedDate >= s.CreatedDate
GROUP BY
    a.AgencyCode,
    a.AgencyName
HAVING COUNT(*) >= 1000
ORDER BY
    AvgHoursToClose DESC;
