USE nyc_311_database;

-- B2 (Ananya): Which agencies take the longest to close a request?
-- Question: Average and longest time to close (in hours) per agency.
-- Techniques: INNER JOIN, WHERE filtering, TIMESTAMPDIFF, AVG/MAX, GROUP BY, HAVING.
--
-- Data-quality filter (see date audit in README): 47,539 requests have no ClosedDate
-- and 25,000 have ClosedDate < CreatedDate. Both are excluded so they do not
-- distort the average. HAVING drops agencies with too few closed requests
-- to give a meaningful average.

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
