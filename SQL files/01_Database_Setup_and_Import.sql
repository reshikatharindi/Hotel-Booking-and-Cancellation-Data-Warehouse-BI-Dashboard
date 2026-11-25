-- ============================================================================
-- 01_Database_Setup_and_Import.sql
-- Database setup, schema creation, raw/staging table preparation, and CSV import.

SELECT
    @@SERVERNAME AS ServerName,
    @@VERSION AS SQLServerVersion;

CREATE DATABASE HotelBookingDW;
GO

USE HotelBookingDW;
GO

SELECT DB_NAME() AS CurrentDatabase;

USE HotelBookingDW;
GO

CREATE SCHEMA stg;
GO

CREATE SCHEMA dw;
GO

CREATE SCHEMA mart;
GO

SELECT name
FROM sys.schemas
WHERE name IN ('stg', 'dw', 'mart');

USE HotelBookingDW;
GO

CREATE TABLE stg.HotelBooking (
    hotel                         VARCHAR(50) NULL,
    is_canceled                   INT NULL,
    lead_time                     INT NULL,
    arrival_date_year             INT NULL,
    arrival_date_month            VARCHAR(20) NULL,
    arrival_date_week_number      INT NULL,
    arrival_date_day_of_month     INT NULL,
    stays_in_weekend_nights       INT NULL,
    stays_in_week_nights          INT NULL,
    adults                        INT NULL,
    children                      DECIMAL(10,2) NULL,
    babies                        INT NULL,
    meal                          VARCHAR(20) NULL,
    country                       VARCHAR(20) NULL,
    market_segment                VARCHAR(50) NULL,
    distribution_channel          VARCHAR(50) NULL,
    is_repeated_guest             INT NULL,
    previous_cancellations        INT NULL,
    previous_bookings_not_canceled INT NULL,
    reserved_room_type            VARCHAR(10) NULL,
    assigned_room_type            VARCHAR(10) NULL,
    booking_changes               INT NULL,
    deposit_type                  VARCHAR(50) NULL,
    agent                         VARCHAR(50) NULL,
    company                       VARCHAR(50) NULL,
    days_in_waiting_list          INT NULL,
    customer_type                 VARCHAR(50) NULL,
    adr                           DECIMAL(12,2) NULL,
    required_car_parking_spaces   INT NULL,
    total_of_special_requests     INT NULL,
    reservation_status            VARCHAR(30) NULL,
    reservation_status_date       VARCHAR(30) NULL
);
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'HotelBooking'
ORDER BY ORDINAL_POSITION;


SELECT COUNT(*) AS ColumnCount
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'HotelBooking';

  USE HotelBookingDW;
GO

DROP TABLE IF EXISTS dbo.HotelBooking_RawImport;
GO

USE HotelBookingDW;
GO

DROP TABLE IF EXISTS dbo.HotelBooking_RawImport;
GO

CREATE TABLE dbo.HotelBooking_RawImport
(
    hotel                          NVARCHAR(100) NULL,
    is_canceled                    NVARCHAR(100) NULL,
    lead_time                      NVARCHAR(100) NULL,
    arrival_date_year              NVARCHAR(100) NULL,
    arrival_date_month             NVARCHAR(100) NULL,
    arrival_date_week_number       NVARCHAR(100) NULL,
    arrival_date_day_of_month      NVARCHAR(100) NULL,
    stays_in_weekend_nights        NVARCHAR(100) NULL,
    stays_in_week_nights           NVARCHAR(100) NULL,
    adults                         NVARCHAR(100) NULL,
    children                       NVARCHAR(100) NULL,
    babies                         NVARCHAR(100) NULL,
    meal                           NVARCHAR(100) NULL,
    country                        NVARCHAR(100) NULL,
    market_segment                 NVARCHAR(100) NULL,
    distribution_channel           NVARCHAR(100) NULL,
    is_repeated_guest              NVARCHAR(100) NULL,
    previous_cancellations         NVARCHAR(100) NULL,
    previous_bookings_not_canceled NVARCHAR(100) NULL,
    reserved_room_type             NVARCHAR(100) NULL,
    assigned_room_type             NVARCHAR(100) NULL,
    booking_changes                NVARCHAR(100) NULL,
    deposit_type                   NVARCHAR(100) NULL,
    agent                          NVARCHAR(100) NULL,
    company                        NVARCHAR(100) NULL,
    days_in_waiting_list           NVARCHAR(100) NULL,
    customer_type                  NVARCHAR(100) NULL,
    adr                            NVARCHAR(100) NULL,
    required_car_parking_spaces    NVARCHAR(100) NULL,
    total_of_special_requests      NVARCHAR(100) NULL,
    reservation_status             NVARCHAR(100) NULL,
    reservation_status_date        NVARCHAR(100) NULL
);
GO


SELECT COUNT(*) AS ColumnCount
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'HotelBooking_RawImport';

USE HotelBookingDW;
GO


BULK INSERT dbo.HotelBooking_RawImport
FROM 'C:\PATH\TO\hotel_bookings.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


SELECT COUNT(*) AS RawRowCount
FROM dbo.HotelBooking_RawImport;




SELECT COUNT(*) AS TotalRows
FROM dbo.HotelBooking_RawImport;

SELECT COUNT(*) AS TotalColumns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'HotelBooking_RawImport';


  SELECT
    SUM(CASE WHEN children IS NULL
                  OR LTRIM(RTRIM(children)) = ''
                  OR UPPER(LTRIM(RTRIM(children))) = 'NA'
             THEN 1 ELSE 0 END) AS MissingChildren,

    SUM(CASE WHEN country IS NULL
                  OR LTRIM(RTRIM(country)) = ''
                  OR UPPER(LTRIM(RTRIM(country))) = 'NA'
             THEN 1 ELSE 0 END) AS MissingCountry,

    SUM(CASE WHEN agent IS NULL
                  OR LTRIM(RTRIM(agent)) = ''
                  OR UPPER(LTRIM(RTRIM(agent))) = 'NA'
             THEN 1 ELSE 0 END) AS MissingAgent,

    SUM(CASE WHEN company IS NULL
                  OR LTRIM(RTRIM(company)) = ''
                  OR UPPER(LTRIM(RTRIM(company))) = 'NA'
             THEN 1 ELSE 0 END) AS MissingCompany
FROM dbo.HotelBooking_RawImport



SELECT TOP (30)
    country,
    COUNT(*) AS Frequency
FROM dbo.HotelBooking_RawImport
GROUP BY country
ORDER BY Frequency DESC;;


SELECT TOP (30)
    agent,
    COUNT(*) AS Frequency
FROM dbo.HotelBooking_RawImport
GROUP BY agent
ORDER BY Frequency DESC;



SELECT TOP (30)
    company,
    COUNT(*) AS Frequency
FROM dbo.HotelBooking_RawImport
GROUP BY company
ORDER BY Frequency DESC;


SELECT
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(country)))
                  IN ('NA', 'N/A', 'NULL', 'NONE', 'NAN')
             THEN 1 ELSE 0 END) AS CountryMissingMarkers,

    SUM(CASE WHEN UPPER(LTRIM(RTRIM(agent)))
                  IN ('NA', 'N/A', 'NULL', 'NONE', 'NAN')
             THEN 1 ELSE 0 END) AS AgentMissingMarkers,

    SUM(CASE WHEN UPPER(LTRIM(RTRIM(company)))
                  IN ('NA', 'N/A', 'NULL', 'NONE', 'NAN')
             THEN 1 ELSE 0 END) AS CompanyMissingMarkers
FROM dbo.HotelBooking_RawImport;



SELECT
    COUNT(*) AS InvalidOrMissingADR
FROM dbo.HotelBooking_RawImport
WHERE TRY_CONVERT(
        DECIMAL(12,2),
        NULLIF(LTRIM(RTRIM(adr)), '')
      ) IS NULL;



      SELECT
    adr,
    COUNT(*) AS Frequency
FROM dbo.HotelBooking_RawImport
WHERE TRY_CONVERT(
        DECIMAL(12,2),
        NULLIF(LTRIM(RTRIM(adr)), '')
      ) IS NULL
GROUP BY adr
ORDER BY Frequency DESC;
