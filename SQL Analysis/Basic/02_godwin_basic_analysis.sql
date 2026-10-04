-- B2: Top 10 most frequently reported complaint types
-- Technique: INNER JOIN, GROUP BY, COUNT, ORDER BY, LIMIT

SELECT
    c.Problem,
    COUNT(*) AS TotalRequests
FROM servicerequest AS s
INNER JOIN problemcategory AS c
    ON s.CategoryID = c.CategoryID
GROUP BY c.Problem
ORDER BY TotalRequests DESC
LIMIT 10;