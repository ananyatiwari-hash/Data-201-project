USE nyc_311_database;

-- A2 (Ananya): What are the top 3 complaint types in each borough,
--              and what share of that borough's requests does each one make up?
-- Techniques: two chained CTEs, 3-table JOIN, GROUP BY,
--             ROW_NUMBER() OVER (PARTITION BY ...) and
--             SUM() OVER (PARTITION BY ...) window functions.
--
-- Unlike Godwin's citywide ranking, this ranks complaints WITHIN each borough,
-- so it shows how problems differ by area. 'Unspecified' and missing boroughs
-- are excluded. This joins ~4 million requests, so it may take a few minutes;
-- check Workbench's Action Output before re-running.

WITH borough_complaints AS (
    SELECT
        l.Borough,
        c.Problem,
        COUNT(*) AS TotalRequests
    FROM servicerequest AS s
    JOIN location AS l
        ON s.LocationID = l.LocationID
    JOIN problemcategory AS c
        ON s.CategoryID = c.CategoryID
    WHERE l.Borough IN ('BROOKLYN', 'QUEENS', 'BRONX', 'MANHATTAN', 'STATEN ISLAND')
    GROUP BY
        l.Borough,
        c.Problem
),
ranked_complaints AS (
    SELECT
        Borough,
        Problem,
        TotalRequests,
        ROW_NUMBER() OVER (
            PARTITION BY Borough
            ORDER BY TotalRequests DESC, Problem
        ) AS RankInBorough,
        ROUND(
            100 * TotalRequests / SUM(TotalRequests) OVER (PARTITION BY Borough),
            1
        ) AS PctOfBoroughRequests
    FROM borough_complaints
)
SELECT
    Borough,
    RankInBorough,
    Problem,
    TotalRequests,
    PctOfBoroughRequests
FROM ranked_complaints
WHERE RankInBorough <= 3
ORDER BY
    Borough,
    RankInBorough;
