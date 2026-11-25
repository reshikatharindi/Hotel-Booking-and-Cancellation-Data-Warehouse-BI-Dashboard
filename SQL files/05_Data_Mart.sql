-- ============================================================================
-- 05_Data_Mart.sql
-- Data mart creation, population, and validation.
-- ============================================================================

/* ============================================================
   TASK 6- DATA MART DEVELOPMENT
   Step 6.1- Create Booking & Cancellation Analysis Data Mart

   Purpose:
      - Create a department-specific analytical data mart
      - Support hotel booking and cancellation analysis
      - Provide a simplified structure for Power BI reporting
      - Combine important dimensional attributes and measures
        required by hotel managers and analysts

   Target Users:
      - Hotel Management
      - Reservation Management
      - Revenue Management
      - Business Analysts

   Grain: One row = One booking record
   ============================================================ */

USE HotelBookingDW;
GO

CREATE TABLE mart.BookingCancellationAnalysis
(
    MartBookingKey BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_BookingCancellationAnalysis PRIMARY KEY,

    -- Date attributes
    ArrivalDate DATE NOT NULL,
    ArrivalYear INT NOT NULL,
    ArrivalQuarter VARCHAR(10) NOT NULL,
    ArrivalMonthNumber INT NOT NULL,
    ArrivalMonth VARCHAR(20) NOT NULL,

    -- Hotel
    HotelType VARCHAR(50) NOT NULL,

    -- Customer profile
    CustomerType VARCHAR(50) NOT NULL,
    Country VARCHAR(20) NOT NULL,
    IsRepeatedGuest INT NOT NULL,

    -- Market profile
    MarketSegment VARCHAR(50) NOT NULL,
    DistributionChannel VARCHAR(50) NOT NULL,

    -- Booking profile
    MealType VARCHAR(20) NOT NULL,
    DepositType VARCHAR(50) NOT NULL,

    -- Room profile
    ReservedRoomType VARCHAR(10) NOT NULL,
    AssignedRoomType VARCHAR(10) NOT NULL,

    -- Reservation status
    ReservationStatus VARCHAR(30) NOT NULL,

    -- Measures
    BookingCount INT NOT NULL,
    IsCanceled INT NOT NULL,
    LeadTime INT NOT NULL,
    TotalStayNights INT NOT NULL,
    TotalGuests DECIMAL(10,2) NOT NULL,
    ADR DECIMAL(12,2) NOT NULL,
    PreviousCancellations INT NOT NULL,
    BookingChanges INT NOT NULL,
    DaysInWaitingList INT NOT NULL,
    RequiredCarParkingSpaces INT NOT NULL,
    TotalSpecialRequests INT NOT NULL
);
GO


/* ============================================================
  
   TASK 6 - DATA MART DEVELOPMENT
   Step 6.1.1- Validate Data Mart Structure

   Purpose:
      - Confirm the data mart table was created successfully
      - Review columns before loading warehouse data
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'mart'
  AND TABLE_NAME = 'BookingCancellationAnalysis'
ORDER BY ORDINAL_POSITION;
GO

/* ============================================================
   TASK 6- DATA MART DEVELOPMENT
   Step 6.2 - Populate Booking & Cancellation Analysis Data Mart

   Purpose:
      - Load analytical booking data from the dimensional
        warehouse into the department-specific data mart
      - Combine fact measures with relevant dimension attributes
      - Prepare a simplified dataset for Power BI analysis

   Source:dw.FactBooking and related dimension tables

   Target:mart.BookingCancellationAnalysis

   Grain:One row = One booking record
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO mart.BookingCancellationAnalysis
(
    ArrivalDate,
    ArrivalYear,
    ArrivalQuarter,
    ArrivalMonthNumber,
    ArrivalMonth,

    HotelType,

    CustomerType,
    Country,
    IsRepeatedGuest,

    MarketSegment,
    DistributionChannel,

    MealType,
    DepositType,

    ReservedRoomType,
    AssignedRoomType,

    ReservationStatus,

    BookingCount,
    IsCanceled,
    LeadTime,
    TotalStayNights,
    TotalGuests,
    ADR,
    PreviousCancellations,
    BookingChanges,
    DaysInWaitingList,
    RequiredCarParkingSpaces,
    TotalSpecialRequests
)

SELECT
    d.FullDate,
    d.YearNumber,
    d.QuarterName,
    d.MonthNumber,
    d.MonthName,

    h.HotelType,

    c.CustomerType,
    c.Country,
    c.IsRepeatedGuest,

    m.MarketSegment,
    m.DistributionChannel,

    bp.MealType,
    bp.DepositType,

    r.ReservedRoomType,
    r.AssignedRoomType,

    rs.ReservationStatus,

    f.BookingCount,
    f.IsCanceled,
    f.LeadTime,
    f.TotalStayNights,
    f.TotalGuests,
    f.ADR,
    f.PreviousCancellations,
    f.BookingChanges,
    f.DaysInWaitingList,
    f.RequiredCarParkingSpaces,
    f.TotalSpecialRequests

FROM dw.FactBooking f

INNER JOIN dw.DimDate d
    ON f.ArrivalDateKey = d.DateKey

INNER JOIN dw.DimHotel h
    ON f.HotelKey = h.HotelKey

INNER JOIN dw.DimCustomer c
    ON f.CustomerKey = c.CustomerKey

INNER JOIN dw.DimMarket m
    ON f.MarketKey = m.MarketKey

INNER JOIN dw.DimBookingProfile bp
    ON f.BookingProfileKey = bp.BookingProfileKey

INNER JOIN dw.DimRoom r
    ON f.RoomKey = r.RoomKey

INNER JOIN dw.DimReservationStatus rs
    ON f.StatusKey = rs.StatusKey;
GO


/* ============================================================
   TASK 6 - DATA MART DEVELOPMENT
   Step 6.3 - Validate Data Mart Load

   Purpose:
      - Confirm all warehouse booking records were loaded
      - Validate core analytical measures
      - Compare data mart totals with the warehouse
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    COUNT(*) AS TotalMartRows,
    SUM(BookingCount) AS TotalBookings,
    SUM(IsCanceled) AS TotalCancellations,

    SUM(CASE
            WHEN IsCanceled = 0 THEN 1
            ELSE 0
        END) AS TotalNonCanceled,

    CAST(
        100.0 * SUM(IsCanceled)
        / NULLIF(SUM(BookingCount), 0)
        AS DECIMAL(10,2)
    ) AS CancellationRatePercent,

    CAST(AVG(ADR) AS DECIMAL(12,2))
        AS AverageADR,

    CAST(
        AVG(CAST(LeadTime AS DECIMAL(12,2)))
        AS DECIMAL(12,2)
    ) AS AverageLeadTime,

    SUM(TotalStayNights) AS TotalStayNights,
    SUM(TotalGuests) AS TotalGuests

FROM mart.BookingCancellationAnalysis;
GO

/* ============================================================
   TASK 6-DATA MART DEVELOPMENT
   Step 6.4 - Final Data Mart Analytical Validation

   Purpose:
      - Validate that the data mart supports departmental
        booking and cancellation analysis
      - Compare booking performance by hotel type
      - Verify aggregation of key BI measures
      - Provide evidence that the mart is ready for Power BI
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    HotelType,

    SUM(BookingCount) AS TotalBookings,

    SUM(IsCanceled) AS TotalCancellations,

    SUM(CASE
            WHEN IsCanceled = 0 THEN 1
            ELSE 0
        END) AS NonCanceledBookings,

    CAST(
        100.0 * SUM(IsCanceled)
        / NULLIF(SUM(BookingCount), 0)
        AS DECIMAL(10,2)
    ) AS CancellationRatePercent,

    CAST(
        AVG(ADR)
        AS DECIMAL(12,2)
    ) AS AverageADR,

    CAST(
        AVG(CAST(LeadTime AS DECIMAL(12,2)))
        AS DECIMAL(12,2)
    ) AS AverageLeadTime,

    SUM(TotalStayNights) AS TotalStayNights,

    SUM(TotalGuests) AS TotalGuests

FROM mart.BookingCancellationAnalysis

GROUP BY HotelType

ORDER BY HotelType;
GO
