USE nyc_311_database;

-- Verify that the four relational tables join correctly.

SELECT
    s.RequestID,
    a.AgencyName,
    c.Problem,
    c.ProblemDetail,
    l.Borough,
    l.City,
    s.CreatedDate,
    s.Status
FROM servicerequest AS s

LEFT JOIN agency AS a
    ON s.AgencyCode = a.AgencyCode
LEFT JOIN problemcategory AS c
    ON s.CategoryID = c.CategoryID
LEFT JOIN location AS l
    ON s.LocationID = l.LocationID
ORDER BY s.RequestID
LIMIT 10;