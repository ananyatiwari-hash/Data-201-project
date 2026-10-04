-- REFERENCE / fresh rebuild only. Do NOT rerun this against populated staging.
-- This uses the original 44-column export table as the exact schema template.
-- If rebuilding without that table, tools/generate_staging_sql.py reads your
-- CSV header and generates the complete CREATE TABLE and LOAD DATA script.
CREATE DATABASE IF NOT EXISTS nyc_311_staging
 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE TABLE nyc_311_staging.export_full LIKE nyc_311_staging.export;
-- Before import, verify the template has exactly 44 original columns in CSV order.
SHOW COLUMNS FROM nyc_311_staging.export_full;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 26.7/Uploads/NYC.csv'
INTO TABLE nyc_311_staging.export_full CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;
SHOW WARNINGS;
SELECT COUNT(*) AS StagingRows FROM nyc_311_staging.export_full;
-- Expected for the original reconciled snapshot: 22659530.
-- Historical 113-row repair is NOT repeated automatically. Reconcile any mismatch.
ALTER TABLE nyc_311_staging.export_full
 ADD COLUMN RequestID_Check VARCHAR(32)
 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
 GENERATED ALWAYS AS (TRIM(`Unique Key`)) VIRTUAL, ALGORITHM=INPLACE;
ALTER TABLE nyc_311_staging.export_full
 ADD INDEX idx_request_id_check (RequestID_Check), ALGORITHM=INPLACE, LOCK=NONE;
