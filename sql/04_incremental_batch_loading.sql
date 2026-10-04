USE nyc_311_database;

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Preserve any existing progress.
CREATE TABLE IF NOT EXISTS relational_load_progress (
    LoadID INT PRIMARY KEY,
    LastSourceKey VARCHAR(32)
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_unicode_ci NOT NULL,
    SourceRowsProcessed BIGINT NOT NULL DEFAULT 0,
    RequestsInserted BIGINT NOT NULL DEFAULT 0
) ENGINE = InnoDB;

INSERT INTO relational_load_progress (
    LoadID,
    LastSourceKey,
    SourceRowsProcessed,
    RequestsInserted
)
SELECT 1, '', 0, 0
WHERE NOT EXISTS (
    SELECT 1
    FROM relational_load_progress
    WHERE LoadID = 1
);

-- Replace only the procedure, not your data.
DROP PROCEDURE IF EXISTS load_relational_batches;

DELIMITER $$

CREATE PROCEDURE load_relational_batches(IN p_batches INT)
BEGIN
    DECLARE v_after VARCHAR(32)
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_unicode_ci;

    DECLARE v_rows INT DEFAULT 0;
    DECLARE v_expected INT DEFAULT 0;
    DECLARE v_inserted INT DEFAULT 0;
    DECLARE v_batches INT DEFAULT 0;
    DECLARE v_lock INT DEFAULT 0;
    DECLARE v_safe_updates INT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;

        SET SESSION sql_safe_updates = v_safe_updates;

        IF v_lock = 1 THEN
            DO RELEASE_LOCK('nyc_311_relational_loader');
        END IF;

        RESIGNAL;
    END;

    SET v_safe_updates = @@SESSION.sql_safe_updates;

    -- Prevent simultaneous loader calls.
    SET v_lock = GET_LOCK('nyc_311_relational_loader', 0);

    IF COALESCE(v_lock, 0) <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Another relational loader is running.';
    END IF;

    IF p_batches IS NULL OR p_batches < 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Specify at least one batch.';
    END IF;

    SET SESSION foreign_key_checks = 1;
    SET SESSION sql_safe_updates = 0;

    DROP TEMPORARY TABLE IF EXISTS tmp_request_batch;

    CREATE TEMPORARY TABLE tmp_request_batch (
        SourceKey VARCHAR(32) NOT NULL,
        RequestID BIGINT NOT NULL PRIMARY KEY,
        AgencyCode VARCHAR(20) NOT NULL,
        AgencyName VARCHAR(255) NOT NULL,
        Problem VARCHAR(255) NOT NULL,
        ProblemDetail VARCHAR(255),
        IncidentAddress VARCHAR(255),
        City VARCHAR(100),
        Borough VARCHAR(100),
        IncidentZip VARCHAR(20),
        Latitude DECIMAL(12,9),
        Longitude DECIMAL(12,9),
        CreatedDate DATETIME NOT NULL,
        ClosedDate DATETIME,
        Status VARCHAR(100),
        SubmissionChannel VARCHAR(100),
        LocationType VARCHAR(255),
        ResolutionDescription TEXT
    ) ENGINE = InnoDB
      DEFAULT CHARSET = utf8mb4
      COLLATE = utf8mb4_unicode_ci;

    SELECT LastSourceKey INTO v_after
    FROM relational_load_progress
    WHERE LoadID = 1;

    batch_loop: WHILE v_batches < p_batches DO

        START TRANSACTION;

        DELETE FROM tmp_request_batch;

        -- Read and convert the next 50,000 source rows.
        INSERT INTO tmp_request_batch (
            SourceKey,
            RequestID,
            AgencyCode,
            AgencyName,
            Problem,
            ProblemDetail,
            IncidentAddress,
            City,
            Borough,
            IncidentZip,
            Latitude,
            Longitude,
            CreatedDate,
            ClosedDate,
            Status,
            SubmissionChannel,
            LocationType,
            ResolutionDescription
        )
        SELECT
            RequestID_Check,
            CAST(RequestID_Check AS UNSIGNED),
            TRIM(`Agency`),

            CASE
                WHEN TRIM(`Agency`) = 'DHS'
                THEN 'Department of Homeless Services'
                ELSE TRIM(`Agency Name`)
            END,

            TRIM(`Problem (formerly Complaint Type)`),

            NULLIF(
                TRIM(`Problem Detail (formerly Descriptor)`), ''
            ),

            NULLIF(TRIM(`Incident Address`), ''),
            NULLIF(TRIM(`City`), ''),
            NULLIF(TRIM(`Borough`), ''),
            NULLIF(TRIM(`Incident Zip`), ''),

            CAST(
                NULLIF(TRIM(`Latitude`), '')
                AS DECIMAL(12,9)
            ),

            CAST(
                NULLIF(TRIM(`Longitude`), '')
                AS DECIMAL(12,9)
            ),

            STR_TO_DATE(
                TRIM(`Created Date`),
                '%m/%d/%Y %h:%i:%s %p'
            ),

            STR_TO_DATE(
                NULLIF(TRIM(`Closed Date`), ''),
                '%m/%d/%Y %h:%i:%s %p'
            ),

            NULLIF(TRIM(`Status`), ''),
            NULLIF(TRIM(`Open Data Channel Type`), ''),
            NULLIF(TRIM(`Location Type`), ''),
            NULLIF(TRIM(`Resolution Description`), '')

        FROM export_full FORCE INDEX (idx_request_id_check)
        WHERE RequestID_Check > v_after
        ORDER BY RequestID_Check
        LIMIT 50000;

        SET v_rows = ROW_COUNT();

        IF v_rows = 0 THEN
            COMMIT;
            LEAVE batch_loop;
        END IF;

        -- Explicit collation fixes the previous error.
        IF EXISTS (
            SELECT 1
            FROM tmp_request_batch
            WHERE SourceKey <>
                (
                    CAST(
                        RequestID AS CHAR CHARACTER SET utf8mb4
                    ) COLLATE utf8mb4_unicode_ci
                )
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'Request ID conversion needs review.';
        END IF;

        -- 1. Load agencies.
        UPDATE agency
        SET AgencyName = 'Department of Homeless Services'
        WHERE AgencyCode = 'DHS';

        INSERT INTO agency (AgencyCode, AgencyName)
        SELECT DISTINCT
            b.AgencyCode,
            b.AgencyName
        FROM tmp_request_batch AS b
        LEFT JOIN agency AS a
            ON a.AgencyCode = b.AgencyCode
        WHERE a.AgencyCode IS NULL;

        IF EXISTS (
            SELECT 1
            FROM tmp_request_batch AS b
            JOIN agency AS a
                ON a.AgencyCode = b.AgencyCode
            WHERE a.AgencyName <> b.AgencyName
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'An agency name conflict needs review.';
        END IF;

        -- 2. Load problem categories.
        INSERT INTO problemcategory (
            Problem,
            ProblemDetail
        )
        SELECT DISTINCT
            b.Problem,
            b.ProblemDetail
        FROM tmp_request_batch AS b
        LEFT JOIN problemcategory AS c
            ON c.Problem = b.Problem
           AND c.ProblemDetail <=> b.ProblemDetail
        WHERE c.CategoryID IS NULL;

        -- 3. Load locations.
        INSERT INTO location (
            IncidentAddress,
            City,
            Borough,
            IncidentZip,
            Latitude,
            Longitude
        )
        SELECT DISTINCT
            b.IncidentAddress,
            b.City,
            b.Borough,
            b.IncidentZip,
            b.Latitude,
            b.Longitude
        FROM tmp_request_batch AS b
        LEFT JOIN location AS l
            ON l.IncidentAddress <=> b.IncidentAddress
           AND l.City <=> b.City
           AND l.Borough <=> b.Borough
           AND l.IncidentZip <=> b.IncidentZip
           AND l.Latitude <=> b.Latitude
           AND l.Longitude <=> b.Longitude
        WHERE l.LocationID IS NULL;

        -- Determine how many new requests should be inserted.
        SELECT COUNT(*) INTO v_expected
        FROM tmp_request_batch AS b
        LEFT JOIN servicerequest AS s
            ON s.RequestID = b.RequestID
        WHERE s.RequestID IS NULL;

        -- 4. Load service requests and link their parent IDs.
        INSERT INTO servicerequest (
            RequestID,
            AgencyCode,
            CategoryID,
            LocationID,
            CreatedDate,
            ClosedDate,
            Status,
            SubmissionChannel,
            LocationType,
            ResolutionDescription
        )
        SELECT
            b.RequestID,
            b.AgencyCode,
            c.CategoryID,
            l.LocationID,
            b.CreatedDate,
            b.ClosedDate,
            b.Status,
            b.SubmissionChannel,
            b.LocationType,
            b.ResolutionDescription
        FROM tmp_request_batch AS b
        JOIN problemcategory AS c
            ON c.Problem = b.Problem
           AND c.ProblemDetail <=> b.ProblemDetail
        JOIN location AS l
            ON l.IncidentAddress <=> b.IncidentAddress
           AND l.City <=> b.City
           AND l.Borough <=> b.Borough
           AND l.IncidentZip <=> b.IncidentZip
           AND l.Latitude <=> b.Latitude
           AND l.Longitude <=> b.Longitude
        LEFT JOIN servicerequest AS s
            ON s.RequestID = b.RequestID
        WHERE s.RequestID IS NULL;

        SET v_inserted = ROW_COUNT();

        IF v_inserted <> v_expected THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'Request mapping count mismatch.';
        END IF;

        -- Save progress in the same transaction as the data.
        SELECT MAX(SourceKey) INTO v_after
        FROM tmp_request_batch;

        UPDATE relational_load_progress
        SET
            LastSourceKey = v_after,
            SourceRowsProcessed = SourceRowsProcessed + v_rows,
            RequestsInserted = RequestsInserted + v_inserted
        WHERE LoadID = 1;

        COMMIT;

        SET v_batches = v_batches + 1;

    END WHILE;

    DROP TEMPORARY TABLE tmp_request_batch;

    SET SESSION sql_safe_updates = v_safe_updates;

    DO RELEASE_LOCK('nyc_311_relational_loader');
    SET v_lock = 0;

    SELECT
        LoadID,
        LastSourceKey,
        SourceRowsProcessed,
        RequestsInserted
    FROM relational_load_progress
    WHERE LoadID = 1;

END$$

DELIMITER ;

-- Test one complete batch through all four tables.
-- Load 50k
CALL load_relational_batches(1);

-- Load 1 million
CALL nyc_311_database.load_relational_batches(20);