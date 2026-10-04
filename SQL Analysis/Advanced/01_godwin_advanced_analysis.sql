USE nyc_311_database;

-- A1: Rank complaint types by total service requests.
-- Techniques: Subquery, DENSE_RANK(), ORDER BY.

SELECT
    Problem,
    TotalRequests,
    DENSE_RANK() OVER (
        ORDER BY TotalRequests DESC
    ) AS ComplaintRank

FROM (
    SELECT
        c.Problem,
        COUNT(*) AS TotalRequests
    FROM servicerequest AS s
    JOIN problemcategory AS c
        ON s.CategoryID = c.CategoryID
    GROUP BY c.Problem
) AS ComplaintCounts

ORDER BY ComplaintRank, Problem
LIMIT 5;