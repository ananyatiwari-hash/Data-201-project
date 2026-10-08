USE nyc_311_database;

-- B1: Share of requests by submission channel.
-- Techniques: GROUP BY, COUNT, COALESCE, subquery in SELECT.

SELECT
    COALESCE(NULLIF(TRIM(s.SubmissionChannel), ''), 'Unknown') AS SubmissionChannel,
    COUNT(*) AS TotalRequests,
    ROUND(
        100 * COUNT(*) / (SELECT COUNT(*) FROM servicerequest),
        2
    ) AS PctOfAllRequests
FROM servicerequest AS s
GROUP BY
    COALESCE(NULLIF(TRIM(s.SubmissionChannel), ''), 'Unknown')
ORDER BY
    TotalRequests DESC;
