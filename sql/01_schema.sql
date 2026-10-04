-- Fresh EMPTY database only. Do not rerun on the populated project.
CREATE DATABASE nyc_311_database
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nyc_311_database;

CREATE TABLE agency (
    AgencyCode VARCHAR(20) NOT NULL,
    AgencyName VARCHAR(255) NOT NULL,
    PRIMARY KEY (AgencyCode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE problemcategory (
    CategoryID INT NOT NULL AUTO_INCREMENT,
    Problem VARCHAR(255) NOT NULL,
    ProblemDetail VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (CategoryID),
    KEY idx_category_lookup (Problem, ProblemDetail)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE location (
    LocationID INT NOT NULL AUTO_INCREMENT,
    IncidentAddress VARCHAR(255) DEFAULT NULL,
    City VARCHAR(100) DEFAULT NULL,
    Borough VARCHAR(100) DEFAULT NULL,
    IncidentZip VARCHAR(20) DEFAULT NULL,
    Latitude DECIMAL(12,9) DEFAULT NULL,
    Longitude DECIMAL(12,9) DEFAULT NULL,
    PRIMARY KEY (LocationID),
    KEY idx_location_lookup (
        IncidentAddress, City, Borough, IncidentZip, Latitude, Longitude
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE servicerequest (
    RequestID BIGINT NOT NULL,
    AgencyCode VARCHAR(20) NOT NULL,
    CategoryID INT NOT NULL,
    LocationID INT DEFAULT NULL,
    CreatedDate DATETIME NOT NULL,
    ClosedDate DATETIME DEFAULT NULL,
    Status VARCHAR(100) DEFAULT NULL,
    SubmissionChannel VARCHAR(100) DEFAULT NULL,
    LocationType VARCHAR(255) DEFAULT NULL,
    ResolutionDescription TEXT,
    PRIMARY KEY (RequestID),
    KEY AgencyCode (AgencyCode),
    KEY CategoryID (CategoryID),
    KEY LocationID (LocationID),
    CONSTRAINT servicerequest_ibfk_1
        FOREIGN KEY (AgencyCode) REFERENCES agency (AgencyCode),
    CONSTRAINT servicerequest_ibfk_2
        FOREIGN KEY (CategoryID) REFERENCES problemcategory (CategoryID),
    CONSTRAINT servicerequest_ibfk_3
        FOREIGN KEY (LocationID) REFERENCES location (LocationID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
