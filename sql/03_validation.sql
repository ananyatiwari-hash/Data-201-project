-- Run selected checks individually. Full staging scans may take minutes.
-- Assumes staging tables have been moved into nyc_311_staging.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nyc_311_staging;
SELECT RequestID_Check, COUNT(*) AS Occurrences FROM export_full
GROUP BY RequestID_Check HAVING COUNT(*) > 1 LIMIT 10;
SELECT COUNT(*) AS NondigitIDs FROM export_full
WHERE RequestID_Check NOT REGEXP '^[0-9]+$';
SELECT MAX(CHAR_LENGTH(RequestID_Check)) AS MaxIDLength FROM export_full;

SELECT
 SUM(NULLIF(TRIM(`Unique Key`), '') IS NULL) AS Missing1,
 SUM(NULLIF(TRIM(`Agency`), '') IS NULL) AS Missing2,
 SUM(NULLIF(TRIM(`Agency Name`), '') IS NULL) AS Missing3,
 SUM(NULLIF(TRIM(`Problem (formerly Complaint Type)`), '') IS NULL) AS Missing4,
 SUM(NULLIF(TRIM(`Created Date`), '') IS NULL) AS Missing5
FROM export_full;
-- Missing1..5: Unique Key, Agency, Agency Name, Problem (formerly Complaint Type), Created Date

SELECT
MAX(CHAR_LENGTH(TRIM(`Agency`))) AS MaxLength1,
MAX(CHAR_LENGTH(TRIM(`Agency Name`))) AS MaxLength2,
MAX(CHAR_LENGTH(TRIM(`Problem (formerly Complaint Type)`))) AS MaxLength3,
MAX(CHAR_LENGTH(TRIM(`Problem Detail (formerly Descriptor)`))) AS MaxLength4,
MAX(CHAR_LENGTH(TRIM(`Incident Address`))) AS MaxLength5,
MAX(CHAR_LENGTH(TRIM(`City`))) AS MaxLength6,
MAX(CHAR_LENGTH(TRIM(`Borough`))) AS MaxLength7,
MAX(CHAR_LENGTH(TRIM(`Incident Zip`))) AS MaxLength8,
MAX(CHAR_LENGTH(TRIM(`Status`))) AS MaxLength9,
MAX(CHAR_LENGTH(TRIM(`Open Data Channel Type`))) AS MaxLength10,
MAX(CHAR_LENGTH(TRIM(`Location Type`))) AS MaxLength11
FROM export_full;
-- Destination limits in order: 20, 255, 255, 255, 255, 100, 100, 20, 100, 100, 255

SET @date_pattern = _utf8mb4'^(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/[1-9][0-9]{3} (0[1-9]|1[0-2]):[0-5][0-9]:[0-5][0-9] (AM|PM)$' COLLATE utf8mb4_unicode_ci;
SELECT
 SUM(NULLIF(TRIM(`Created Date`),'') IS NULL OR TRIM(`Created Date`) NOT REGEXP @date_pattern) AS InvalidCreatedFormat,
 SUM(NULLIF(TRIM(`Closed Date`),'') IS NOT NULL AND TRIM(`Closed Date`) NOT REGEXP @date_pattern) AS InvalidClosedFormat,
 SUM(NULLIF(TRIM(`Closed Date`),'') IS NULL) AS MissingClosedDate
FROM export_full;
-- Calendar checks also count nonmatching formats as invalid (optional blanks allowed).
SELECT

SUM(CASE WHEN NULLIF(TRIM(`Created Date`),'') IS NULL THEN 1
 WHEN TRIM(`Created Date`) NOT REGEXP @date_pattern THEN 1
 ELSE CAST(SUBSTRING(TRIM(`Created Date`),4,2) AS UNSIGNED) > DAY(LAST_DAY(CONCAT(SUBSTRING(TRIM(`Created Date`),7,4),'-',SUBSTRING(TRIM(`Created Date`),1,2),'-01'))) END) AS InvalidCreatedCalendar,
SUM(CASE WHEN NULLIF(TRIM(`Closed Date`),'') IS NULL THEN 0
 WHEN TRIM(`Closed Date`) NOT REGEXP @date_pattern THEN 1
 ELSE CAST(SUBSTRING(TRIM(`Closed Date`),4,2) AS UNSIGNED) > DAY(LAST_DAY(CONCAT(SUBSTRING(TRIM(`Closed Date`),7,4),'-',SUBSTRING(TRIM(`Closed Date`),1,2),'-01'))) END) AS InvalidClosedCalendar
FROM export_full;

SELECT
SUM(CASE WHEN NULLIF(TRIM(`Latitude`),'') IS NULL THEN 0 WHEN TRIM(`Latitude`) REGEXP '^[+-]?[0-9]{1,3}([.][0-9]{1,20})?$' THEN ABS(CAST(TRIM(`Latitude`) AS DECIMAL(30,20))) > 90 ELSE 1 END) AS InvalidLatitude,
SUM(NULLIF(TRIM(`Latitude`),'') IS NULL) AS MissingLatitude,
SUM(CASE WHEN NULLIF(TRIM(`Longitude`),'') IS NULL THEN 0 WHEN TRIM(`Longitude`) REGEXP '^[+-]?[0-9]{1,3}([.][0-9]{1,20})?$' THEN ABS(CAST(TRIM(`Longitude`) AS DECIMAL(30,20))) > 180 ELSE 1 END) AS InvalidLongitude,
SUM(NULLIF(TRIM(`Longitude`),'') IS NULL) AS MissingLongitude,
MAX(OCTET_LENGTH(`Resolution Description`)) AS MaxResolutionBytes
FROM export_full;

SELECT TRIM(`Agency Name`) AS AgencyName, COUNT(*) AS Requests FROM export_full WHERE TRIM(Agency)='DHS' GROUP BY TRIM(`Agency Name`);

SELECT
    SUM(a.AgencyCode IS NULL) AS MissingAgency,
    SUM(c.CategoryID IS NULL) AS MissingCategory,
    SUM(s.LocationID IS NOT NULL AND l.LocationID IS NULL)
        AS MissingLocation
FROM nyc_311_database.servicerequest AS s
LEFT JOIN nyc_311_database.agency AS a
    ON s.AgencyCode = a.AgencyCode
LEFT JOIN nyc_311_database.problemcategory AS c
    ON s.CategoryID = c.CategoryID
LEFT JOIN nyc_311_database.location AS l
    ON s.LocationID = l.LocationID;
