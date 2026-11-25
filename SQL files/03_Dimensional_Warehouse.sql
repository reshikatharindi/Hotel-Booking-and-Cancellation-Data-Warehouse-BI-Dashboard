-- ============================================================================
-- 03_Dimensional_Warehouse.sql
-- Dimension and fact table creation, plus warehouse structure validation.
-- ============================================================================

/* ============================================================

   TASK 4 – DIMENSIONAL DATA WAREHOUSE
   Step 4.1.1 – Create Date Dimension

   Purpose:
      - Create the Date Dimension for time-based analysis
      - Support Power BI trend analysis
      - Support drill-down and roll-up using:
        Year → Quarter → Month → Day
      - Provide a surrogate DateKey for FactBooking

   Dimension: dw.DimDate
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.DimDate
(
    DateKey INT NOT NULL PRIMARY KEY,

    FullDate DATE NOT NULL,

    DayNumber INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,

    WeekNumber INT NOT NULL,

    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,

    QuarterNumber INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,

    YearNumber INT NOT NULL,

    CONSTRAINT UQ_DimDate_FullDate UNIQUE (FullDate)
);
GO



/* ============================================================
   TASK 4 – DIMENSIONAL DATA WAREHOUSE
   Step 4.1.2 – Validate Date Dimension Structure
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimDate'
ORDER BY ORDINAL_POSITION;
GO


/* ============================================================
    TASK 4 – DIMENSIONAL DATA WAREHOUSE
   Step 4.2.1 – Create Hotel Dimension

   Purpose:
      - Create a dimension for hotel information
      - Allow comparison between hotel types
      - Provide a surrogate HotelKey for FactBooking

   Dimension:dw.DimHotel
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.DimHotel
(
    HotelKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    HotelType VARCHAR(50) NOT NULL,

    CONSTRAINT UQ_DimHotel_HotelType
        UNIQUE (HotelType)
);
GO


/* ============================================================
   TASK 4 – DIMENSIONAL DATA WAREHOUSE
   Step 4.2.2 – Validate Hotel Dimension Structure
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimHotel'
ORDER BY ORDINAL_POSITION;
GO

/* ============================================================
  
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.3.1 � Create Customer Dimension

   Purpose:
      - Create a dimension for customer profile analysis
      - Support analysis by customer type, country and
        repeated-guest status
      - Provide a surrogate CustomerKey for FactBooking

   Design Assumption:
      - The source dataset does not contain a unique Customer ID.
      - Therefore, this dimension represents customer profiles
        rather than individual identifiable customers.

   Dimension:dw.DimCustomer
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.DimCustomer
(
    CustomerKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    CustomerType VARCHAR(50) NOT NULL,

    Country VARCHAR(20) NOT NULL,

    IsRepeatedGuest INT NOT NULL,

    CONSTRAINT UQ_DimCustomer_Profile
        UNIQUE
        (
            CustomerType,
            Country,
            IsRepeatedGuest
        ),

    CONSTRAINT CK_DimCustomer_IsRepeatedGuest
        CHECK (IsRepeatedGuest IN (0,1))
);
GO

/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.3.2 � Validate Customer Dimension Structure
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimCustomer'
ORDER BY ORDINAL_POSITION;
GO
/* ============================================================

   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.4.1 � Create Room Dimension

   Purpose:
      - Create a dimension for room-related analysis
      - Store reserved and assigned room types
      - Support analysis of room assignment patterns
      - Provide a surrogate RoomKey for FactBooking

   Dimension:dw.DimRoom
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.DimRoom
(
    RoomKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    ReservedRoomType VARCHAR(10) NOT NULL,

    AssignedRoomType VARCHAR(10) NOT NULL,

    CONSTRAINT UQ_DimRoom_Profile
        UNIQUE
        (
            ReservedRoomType,
            AssignedRoomType
        )
);
GO

/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.4.2 � Validate Room Dimension Structure
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimRoom'
ORDER BY ORDINAL_POSITION;
GO

/* ============================================================

   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.5.1 � Create Market Dimension

   Purpose:
      - Create a dimension for booking source/channel analysis
      - Support analysis by market segment and distribution channel
      - Store agent and company identifiers from the source
      - Provide a surrogate MarketKey for FactBooking

   Dimension: dw.DimMarket
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.DimMarket
(
    MarketKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    MarketSegment VARCHAR(50) NOT NULL,

    DistributionChannel VARCHAR(50) NOT NULL,

    Agent VARCHAR(50) NOT NULL,

    Company VARCHAR(50) NOT NULL,

    CONSTRAINT UQ_DimMarket_Profile
        UNIQUE
        (
            MarketSegment,
            DistributionChannel,
            Agent,
            Company
        )
);
GO


/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.5.2 � Validate Market Dimension Structure
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimMarket'
ORDER BY ORDINAL_POSITION;
GO

/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.6.1 � Create Booking Profile Dimension

   Purpose:
      - Create a dimension for booking profile analysis
      - Store meal and deposit type information
      - Support analysis of cancellation patterns by
        meal type and deposit type
      - Provide a surrogate BookingProfileKey for FactBooking

   Dimension:dw.DimBookingProfile
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.DimBookingProfile
(
    BookingProfileKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    MealType VARCHAR(20) NOT NULL,

    DepositType VARCHAR(50) NOT NULL,

    CONSTRAINT UQ_DimBookingProfile
        UNIQUE
        (
            MealType,
            DepositType
        )
);
GO


/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.6.2 � Validate Booking Profile Dimension Structure
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimBookingProfile'
ORDER BY ORDINAL_POSITION;
GO

/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.7.1 � Create Reservation Status Dimension

   Purpose:
      - Create a dimension for reservation status analysis
      - Store reservation status categories
      - Support cancellation, check-out and no-show analysis
      - Provide a surrogate StatusKey for FactBooking

   Dimension:dw.DimReservationStatus
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.DimReservationStatus
(
    StatusKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    ReservationStatus VARCHAR(30) NOT NULL,

    CONSTRAINT UQ_DimReservationStatus
        UNIQUE (ReservationStatus)
);
GO

/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.7.2 � Validate Reservation Status Dimension Structure
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'DimReservationStatus'
ORDER BY ORDINAL_POSITION;
GO

/* ============================================================

   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.8.1 � Create FactBooking

   Business Process:Hotel Booking Management

   Grain:One row represents one booking record from the operational hotel booking dataset.

   Purpose:
      - Create the central fact table of the star schema
      - Connect bookings to the dimensional tables
      - Store quantitative measures for BI analysis
      - Support booking, cancellation, guest, stay and
        ADR analysis

   Fact Table:dw.FactBooking
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE dw.FactBooking
(
    -- Surrogate primary key
    BookingFactKey BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_FactBooking PRIMARY KEY,

    /* --------------------------------------------------------
       Dimension Foreign Keys
       -------------------------------------------------------- */

    ArrivalDateKey INT NOT NULL,
    ReservationStatusDateKey INT NOT NULL,

    HotelKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    RoomKey INT NOT NULL,
    MarketKey INT NOT NULL,
    BookingProfileKey INT NOT NULL,
    StatusKey INT NOT NULL,

    /* --------------------------------------------------------
       Booking Measures
       -------------------------------------------------------- */

    BookingCount INT NOT NULL,

    IsCanceled INT NOT NULL,

    LeadTime INT NOT NULL,

    WeekendNights INT NOT NULL,
    WeekNights INT NOT NULL,
    TotalStayNights INT NOT NULL,

    Adults INT NOT NULL,
    Children DECIMAL(10,2) NOT NULL,
    Babies INT NOT NULL,
    TotalGuests DECIMAL(10,2) NOT NULL,

    PreviousCancellations INT NOT NULL,
    PreviousBookingsNotCanceled INT NOT NULL,

    BookingChanges INT NOT NULL,
    DaysInWaitingList INT NOT NULL,

    ADR DECIMAL(12,2) NOT NULL,

    RequiredCarParkingSpaces INT NOT NULL,
    TotalSpecialRequests INT NOT NULL,

    /* --------------------------------------------------------
       Data Quality Constraints
       -------------------------------------------------------- */

    CONSTRAINT CK_FactBooking_IsCanceled
        CHECK (IsCanceled IN (0,1)),

    CONSTRAINT CK_FactBooking_BookingCount
        CHECK (BookingCount = 1),

    /* --------------------------------------------------------
       Foreign Key Relationships
       -------------------------------------------------------- */

    CONSTRAINT FK_FactBooking_ArrivalDate
        FOREIGN KEY (ArrivalDateKey)
        REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_FactBooking_ReservationStatusDate
        FOREIGN KEY (ReservationStatusDateKey)
        REFERENCES dw.DimDate(DateKey),

    CONSTRAINT FK_FactBooking_Hotel
        FOREIGN KEY (HotelKey)
        REFERENCES dw.DimHotel(HotelKey),

    CONSTRAINT FK_FactBooking_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES dw.DimCustomer(CustomerKey),

    CONSTRAINT FK_FactBooking_Room
        FOREIGN KEY (RoomKey)
        REFERENCES dw.DimRoom(RoomKey),

    CONSTRAINT FK_FactBooking_Market
        FOREIGN KEY (MarketKey)
        REFERENCES dw.DimMarket(MarketKey),

    CONSTRAINT FK_FactBooking_BookingProfile
        FOREIGN KEY (BookingProfileKey)
        REFERENCES dw.DimBookingProfile(BookingProfileKey),

    CONSTRAINT FK_FactBooking_Status
        FOREIGN KEY (StatusKey)
        REFERENCES dw.DimReservationStatus(StatusKey)
);
GO


/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.8.2 � Validate FactBooking Structure

   Purpose:
      - Confirm that FactBooking was created successfully
      - Verify column names and SQL data types
   ============================================================ */

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_NAME = 'FactBooking'
ORDER BY ORDINAL_POSITION;
GO

/* ============================================================
 
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.8.3 � Validate Fact-to-Dimension Relationships

   Purpose:
      - Verify that FactBooking foreign keys were created
      - Confirm relationships between the fact table and
        dimension tables
      - Provide evidence of star-schema implementation
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_SCHEMA_NAME(fk.parent_object_id)
        + '.' +
    OBJECT_NAME(fk.parent_object_id) AS FactTable,

    COL_NAME(
        fkc.parent_object_id,
        fkc.parent_column_id
    ) AS FactColumn,

    OBJECT_SCHEMA_NAME(fk.referenced_object_id)
        + '.' +
    OBJECT_NAME(fk.referenced_object_id) AS DimensionTable,

    COL_NAME(
        fkc.referenced_object_id,
        fkc.referenced_column_id
    ) AS DimensionColumn

FROM sys.foreign_keys fk

INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id

WHERE fk.parent_object_id =
      OBJECT_ID('dw.FactBooking')

ORDER BY ForeignKeyName;
GO
/* ============================================================
   TASK 4 � DIMENSIONAL DATA WAREHOUSE
   Step 4.9 � Final Warehouse Structure Validation

   Purpose:
      - Confirm all dimension and fact tables exist
      - Verify the dimensional warehouse structure
      - Provide final implementation evidence for Task 4
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dw'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
