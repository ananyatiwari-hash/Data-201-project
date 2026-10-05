USE nyc_311_database;

-- B1 (Ananya): How do people submit 311 requests?
-- Question: Which submission channels (phone, online, mobile app, ...) are used most,
--           and what share of all loaded requests does each one account for?
-- Techniques: GROUP BY, COUNT, scalar subquery for the percentage, NULLIF/COALESCE
--             to group blank and missing channels together as 'Unknown'.

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
