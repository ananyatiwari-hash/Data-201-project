USE nyc_311_database;

-- A1: Month-over-month change in request volume (2020).
-- Techniques: Derived tables, self-join, LEFT JOIN, GROUP BY.

SELECT
    cur.RequestMonth,
    cur.TotalRequests,
    prev.TotalRequests AS PrevMonthRequests,
    cur.TotalRequests - prev.TotalRequests AS MonthOverMonthChange,
    ROUND(
        100 * (cur.TotalRequests - prev.TotalRequests) / prev.TotalRequests,
        1
    ) AS PctChange
FROM (
    SELECT
        MONTH(CreatedDate) AS RequestMonth,
        COUNT(*) AS TotalRequests
    FROM servicerequest
    WHERE CreatedDate >= '2020-01-01'
      AND CreatedDate <  '2021-01-01'
    GROUP BY MONTH(CreatedDate)
) AS cur
LEFT JOIN (
    SELECT
        MONTH(CreatedDate) AS RequestMonth,
        COUNT(*) AS TotalRequests
    FROM servicerequest
    WHERE CreatedDate >= '2020-01-01'
      AND CreatedDate <  '2021-01-01'
    GROUP BY MONTH(CreatedDate)
) AS prev
    ON prev.RequestMonth = cur.RequestMonth - 1
ORDER BY cur.RequestMonth;
