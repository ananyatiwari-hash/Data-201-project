USE nyc_311_database;

-- A2: Top 3 complaint types within each borough.
-- Techniques: Subquery, JOIN, GROUP BY,
-- DENSE_RANK(), PARTITION BY.

SELECT
    Borough,
    Problem,
    TotalRequests,
    DENSE_RANK() OVER (
        PARTITION BY Borough
        ORDER BY TotalRequests DESC
    ) AS ComplaintRank

FROM (
    SELECT
        l.Borough,
        c.Problem,
        COUNT(*) AS TotalRequests

    FROM servicerequest AS s

    JOIN location AS l
        ON s.LocationID = l.LocationID

    JOIN problemcategory AS c
        ON s.CategoryID = c.CategoryID

    WHERE l.Borough IN (
        'BRONX',
        'BROOKLYN',
        'MANHATTAN',
        'QUEENS',
        'STATEN ISLAND'
    )

    GROUP BY
        l.Borough,
        c.Problem

) AS ComplaintCounts

ORDER BY
    Borough,
    ComplaintRank,
    Problem;