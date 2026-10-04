USE nyc_311_database;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'nyc_311_database'
  AND CONSTRAINT_NAME = 'PRIMARY'
  AND TABLE_NAME IN (
      'agency',
      'problemcategory',
      'location',
      'servicerequest'
  )
ORDER BY TABLE_NAME;