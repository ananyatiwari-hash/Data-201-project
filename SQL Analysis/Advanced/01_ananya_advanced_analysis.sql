USE nyc_311_database;

-- A1 (Ananya): How did 311 request volume change month to month in 2020?
-- Techniques: CTE (WITH), window function LAG(), DATE_FORMAT, GROUP BY.
--
-- Scope: restricted to 2020 because it is the only fully covered year in the
-- loaded subset (2020: 2,940,153 requests; 2021 is only partially loaded and
-- 2022-2024 are absent). Including 2021 would show a fake "drop" where the
-- batch load stopped.

WITH monthly_requests AS (
    SELECT
        DATE_FORMAT(CreatedDate, '%Y-%m') AS RequestMonth,
        COUNT(*) AS TotalRequests
    FROM servicerequest
    WHERE CreatedDate >= '2020-01-01'
      AND CreatedDate <  '2021-01-01'
    GROUP BY DATE_FORMAT(CreatedDate, '%Y-%m')
)
SELECT
    RequestMonth,
    TotalRequests,
    LAG(TotalRequests) OVER (ORDER BY RequestMonth) AS PrevMonthRequests,
    TotalRequests - LAG(TotalRequests) OVER (ORDER BY RequestMonth)
        AS MonthOverMonthChange,
    ROUND(
        100 * (TotalRequests - LAG(TotalRequests) OVER (ORDER BY RequestMonth))
            / LAG(TotalRequests) OVER (ORDER BY RequestMonth),
        1
    ) AS PctChange
FROM monthly_requests
ORDER BY RequestMonth;
