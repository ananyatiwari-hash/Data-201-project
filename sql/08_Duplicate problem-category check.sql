USE nyc_311_database;

-- Find repeated problem/category combinations.

SELECT
    Problem,
    ProblemDetail,
    COUNT(*) AS DuplicateCount
FROM problemcategory
GROUP BY
    Problem,
    ProblemDetail
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC
LIMIT 10;