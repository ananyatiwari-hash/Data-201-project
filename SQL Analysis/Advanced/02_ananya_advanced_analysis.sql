USE nyc_311_database;

-- A2: Top 3 complaint types in each borough.
-- Techniques: Derived tables, self-join, GROUP BY, HAVING.

SELECT
    a.Borough,
    a.Problem,
    a.TotalRequests,
    COUNT(*) AS RankInBorough
FROM (
    SELECT l.Borough, c.Problem, COUNT(*) AS TotalRequests
    FROM servicerequest AS s
    JOIN location AS l
        ON s.LocationID = l.LocationID
    JOIN problemcategory AS c
        ON s.CategoryID = c.CategoryID
    WHERE l.Borough IN ('BROOKLYN', 'QUEENS', 'BRONX', 'MANHATTAN', 'STATEN ISLAND')
    GROUP BY l.Borough, c.Problem
) AS a
JOIN (
    SELECT l.Borough, c.Problem, COUNT(*) AS TotalRequests
    FROM servicerequest AS s
    JOIN location AS l
        ON s.LocationID = l.LocationID
    JOIN problemcategory AS c
        ON s.CategoryID = c.CategoryID
    WHERE l.Borough IN ('BROOKLYN', 'QUEENS', 'BRONX', 'MANHATTAN', 'STATEN ISLAND')
    GROUP BY l.Borough, c.Problem
) AS b
    ON b.Borough = a.Borough
   AND b.TotalRequests >= a.TotalRequests
GROUP BY
    a.Borough,
    a.Problem,
    a.TotalRequests
HAVING COUNT(*) <= 3
ORDER BY
    a.Borough,
    RankInBorough;
