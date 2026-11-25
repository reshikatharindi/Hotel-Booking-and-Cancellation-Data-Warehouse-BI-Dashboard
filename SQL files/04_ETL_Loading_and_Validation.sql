-- ============================================================================
-- 04_ETL_Loading_and_Validation.sql
-- Dimension loading, fact loading, and ETL validation.

/* ============================================================
  
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.1 – Determine Date Dimension Range

   Purpose:
      - Identify the earliest and latest dates required
        by the warehouse
      - Consider both Arrival Date and Reservation Status Date
      - Establish the range needed for dw.DimDate
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    MIN(AllDates.DateValue) AS EarliestDate,
    MAX(AllDates.DateValue) AS LatestDate
FROM
(
    -- Arrival dates
    SELECT arrival_date AS DateValue
    FROM stg.HotelBooking

    UNION ALL

    -- Reservation status dates
    SELECT TRY_CONVERT(DATE, reservation_status_date)
    FROM stg.HotelBooking
) AS AllDates;
GO


/* ============================================================
  
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.2 – Load Date Dimension

   Purpose:
      - Populate dw.DimDate with all calendar dates required
        by Arrival Date and Reservation Status Date
      - Generate date attributes for time-based BI analysis
      - Support the hierarchy:
            Year → Quarter → Month → Day

   Date Range:2014-10-17 to 2017-09-14
   ============================================================ */

USE HotelBookingDW;
GO

;WITH DateSeries AS
(
    -- Start with the earliest required date
    SELECT CAST('2014-10-17' AS DATE) AS FullDate

    UNION ALL

    -- Generate one day at a time
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < CAST('2017-09-14' AS DATE)
)

INSERT INTO dw.DimDate
(
    DateKey,
    FullDate,
    DayNumber,
    DayName,
    WeekNumber,
    MonthNumber,
    MonthName,
    QuarterNumber,
    QuarterName,
    YearNumber
)
SELECT
    YEAR(FullDate) * 10000
        + MONTH(FullDate) * 100
        + DAY(FullDate) AS DateKey,

    FullDate,

    DAY(FullDate) AS DayNumber,

    DATENAME(WEEKDAY, FullDate) AS DayName,

    DATEPART(ISO_WEEK, FullDate) AS WeekNumber,

    MONTH(FullDate) AS MonthNumber,

    DATENAME(MONTH, FullDate) AS MonthName,

    DATEPART(QUARTER, FullDate) AS QuarterNumber,

    CONCAT(
        'Q',
        DATEPART(QUARTER, FullDate)
    ) AS QuarterName,

    YEAR(FullDate) AS YearNumber

FROM DateSeries

OPTION (MAXRECURSION 0);
GO


/* ============================================================
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.3 – Validate Date Dimension Load

   Purpose:
      - Confirm all required dates were loaded
      - Verify minimum and maximum dates
      - Confirm DateKey generation
   ============================================================ */

SELECT
    COUNT(*) AS TotalDateRows,
    MIN(FullDate) AS EarliestDate,
    MAX(FullDate) AS LatestDate,
    MIN(DateKey) AS MinimumDateKey,
    MAX(DateKey) AS MaximumDateKey
FROM dw.DimDate;
GO


/* ============================================================
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.3 – Preview Date Dimension
   ============================================================ */

SELECT TOP (10) *
FROM dw.DimDate
ORDER BY FullDate;
GO

/* ============================================================
 
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.4 � Load Hotel Dimension

   Purpose:
      - Extract distinct hotel types from staging
      - Load hotel values into dw.DimHotel
      - Generate surrogate HotelKey values automatically
      - Prepare the dimension for FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO dw.DimHotel
(
    HotelType
)
SELECT DISTINCT
    hotel
FROM stg.HotelBooking
WHERE hotel IS NOT NULL;
GO


/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.5 � Validate Hotel Dimension Load
   ============================================================ */

SELECT
    HotelKey,
    HotelType
FROM dw.DimHotel
ORDER BY HotelKey;
GO

/* ============================================================

   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.6 – Load Customer Dimension

   Purpose:
      - Extract distinct customer profiles from staging
      - Load Customer Type, Country and Repeated Guest status
      - Replace missing Country values with 'Unknown'
      - Generate surrogate CustomerKey values
      - Preserve bookings with unavailable country information
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO dw.DimCustomer
(
    CustomerType,
    Country,
    IsRepeatedGuest
)
SELECT DISTINCT
    customer_type,
    COALESCE(country, 'Unknown') AS Country,
    is_repeated_guest
FROM stg.HotelBooking;
GO



/* ============================================================
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.7 – Validate Customer Dimension Load

   Purpose:
      - Confirm customer profiles loaded successfully
      - Verify that missing countries were mapped to 'Unknown'
   ============================================================ */

SELECT COUNT(*) AS TotalCustomerProfiles
FROM dw.DimCustomer;
GO

SELECT
    CustomerKey,
    CustomerType,
    Country,
    IsRepeatedGuest
FROM dw.DimCustomer
WHERE Country = 'Unknown'
ORDER BY CustomerKey;
GO


/* ============================================================
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.7 – Validate Customer Dimension Key Matching

   Purpose:
      - Confirm every staging booking can match a customer
        profile in dw.DimCustomer
      - Prevent missing CustomerKey values during Fact load
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS UnmatchedCustomerRecords
FROM stg.HotelBooking s
LEFT JOIN dw.DimCustomer d
    ON d.CustomerType = s.customer_type
   AND d.Country = COALESCE(s.country, 'Unknown')
   AND d.IsRepeatedGuest = s.is_repeated_guest
WHERE d.CustomerKey IS NULL;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.8 � Load Room Dimension

   Purpose:
      - Extract distinct room profiles from staging
      - Store Reserved Room Type and Assigned Room Type
      - Generate surrogate RoomKey values
      - Prepare room dimension keys for FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO dw.DimRoom
(
    ReservedRoomType,
    AssignedRoomType
)
SELECT DISTINCT
    reserved_room_type,
    assigned_room_type
FROM stg.HotelBooking;
GO


/* ============================================================
  TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.9 � Validate Room Dimension Load

   Purpose:
      - Confirm room profiles were loaded successfully
      - Review reserved and assigned room combinations
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS TotalRoomProfiles
FROM dw.DimRoom;
GO

SELECT
    RoomKey,
    ReservedRoomType,
    AssignedRoomType
FROM dw.DimRoom
ORDER BY RoomKey;
GO


/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.9 � Validate Room Dimension Key Matching

   Purpose:
      - Confirm every staging booking can match a room profile
      - Ensure every booking can receive a valid RoomKey
        during FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS UnmatchedRoomRecords
FROM stg.HotelBooking s
LEFT JOIN dw.DimRoom d
    ON d.ReservedRoomType = s.reserved_room_type
   AND d.AssignedRoomType = s.assigned_room_type
WHERE d.RoomKey IS NULL;
GO

/* ============================================================
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.10 – Load Market Dimension

   Purpose:
      - Extract distinct market profiles from staging
      - Store Market Segment, Distribution Channel,
        Agent and Company information
      - Replace missing Agent and Company values with 'Unknown'
      - Generate surrogate MarketKey values
      - Prepare market dimension keys for FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO dw.DimMarket
(
    MarketSegment,
    DistributionChannel,
    Agent,
    Company
)
SELECT DISTINCT
    market_segment,
    distribution_channel,
    COALESCE(agent, 'Unknown') AS Agent,
    COALESCE(company, 'Unknown') AS Company
FROM stg.HotelBooking;
GO

/* ============================================================
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.11 – Validate Market Dimension Load

   Purpose:
      - Confirm market profiles were loaded successfully
      - Check the total number of distinct market profiles
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS TotalMarketProfiles
FROM dw.DimMarket;
GO

/* ============================================================
   TASK 5 – ETL PROCESS DEVELOPMENT
   Step 5.6.11 – Validate Market Dimension Key Matching

   Purpose:
      - Confirm every staging booking can match a market profile
      - Ensure every booking can receive a valid MarketKey
        during FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS UnmatchedMarketRecords
FROM stg.HotelBooking s
LEFT JOIN dw.DimMarket d
    ON d.MarketSegment = s.market_segment
   AND d.DistributionChannel = s.distribution_channel
   AND d.Agent = COALESCE(s.agent, 'Unknown')
   AND d.Company = COALESCE(s.company, 'Unknown')
WHERE d.MarketKey IS NULL;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.12 � Load Booking Profile Dimension

   Purpose:
      - Extract distinct booking profiles from staging
      - Store Meal Type and Deposit Type
      - Generate surrogate BookingProfileKey values
      - Prepare dimension keys for FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO dw.DimBookingProfile
(
    MealType,
    DepositType
)
SELECT DISTINCT
    meal,
    deposit_type
FROM stg.HotelBooking;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.13 � Validate Booking Profile Dimension

   Purpose:
      - Confirm booking profiles loaded successfully
      - Review Meal Type and Deposit Type combinations
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS TotalBookingProfiles
FROM dw.DimBookingProfile;
GO

SELECT
    BookingProfileKey,
    MealType,
    DepositType
FROM dw.DimBookingProfile
ORDER BY BookingProfileKey;
GO


/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.13 � Validate Booking Profile Key Matching

   Purpose:
      - Confirm every staging booking can match a booking profile
      - Ensure every booking can receive a valid
        BookingProfileKey during FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS UnmatchedBookingProfileRecords
FROM stg.HotelBooking s
LEFT JOIN dw.DimBookingProfile d
    ON d.MealType = s.meal
   AND d.DepositType = s.deposit_type
WHERE d.BookingProfileKey IS NULL;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.14 � Load Reservation Status Dimension

   Purpose:
      - Extract distinct reservation statuses from staging
      - Load reservation status values into the warehouse
      - Generate surrogate StatusKey values
      - Prepare StatusKey for FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO dw.DimReservationStatus
(
    ReservationStatus
)
SELECT DISTINCT
    reservation_status
FROM stg.HotelBooking
WHERE reservation_status IS NOT NULL;
GO


/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.15 � Validate Reservation Status Dimension

   Purpose:
      - Confirm reservation statuses loaded successfully
      - Review generated surrogate StatusKey values
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS TotalReservationStatuses
FROM dw.DimReservationStatus;
GO

SELECT
    StatusKey,
    ReservationStatus
FROM dw.DimReservationStatus
ORDER BY StatusKey;
GO


/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.6.15 � Validate Reservation Status Key Matching

   Purpose:
      - Confirm every staging booking can match a
        reservation status
      - Ensure every booking can receive a valid StatusKey
        during FactBooking loading
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS UnmatchedStatusRecords
FROM stg.HotelBooking s
LEFT JOIN dw.DimReservationStatus d
    ON d.ReservationStatus = s.reservation_status
WHERE d.StatusKey IS NULL;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.7 � FactBooking Pre-Load Foreign Key Validation

   Purpose:
      - Verify that every staging booking can resolve all
        dimension surrogate keys before FactBooking loading
      - Validate both role-playing Date Dimension keys
      - Prevent foreign-key failures during fact loading
      - Confirm readiness for FactBooking ETL load
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    COUNT(*) AS TotalStagingRows,

    SUM(CASE
        WHEN arrivalDate.DateKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedArrivalDates,

    SUM(CASE
        WHEN statusDate.DateKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedStatusDates,

    SUM(CASE
        WHEN h.HotelKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedHotels,

    SUM(CASE
        WHEN c.CustomerKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedCustomers,

    SUM(CASE
        WHEN r.RoomKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedRooms,

    SUM(CASE
        WHEN m.MarketKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedMarkets,

    SUM(CASE
        WHEN bp.BookingProfileKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedBookingProfiles,

    SUM(CASE
        WHEN rs.StatusKey IS NULL
        THEN 1 ELSE 0
    END) AS UnmatchedStatuses

FROM stg.HotelBooking s

LEFT JOIN dw.DimDate arrivalDate
    ON arrivalDate.FullDate = s.arrival_date

LEFT JOIN dw.DimDate statusDate
    ON statusDate.FullDate =
       TRY_CONVERT(DATE, s.reservation_status_date)

LEFT JOIN dw.DimHotel h
    ON h.HotelType = s.hotel

LEFT JOIN dw.DimCustomer c
    ON c.CustomerType = s.customer_type
   AND c.Country = COALESCE(s.country, 'Unknown')
   AND c.IsRepeatedGuest = s.is_repeated_guest

LEFT JOIN dw.DimRoom r
    ON r.ReservedRoomType = s.reserved_room_type
   AND r.AssignedRoomType = s.assigned_room_type

LEFT JOIN dw.DimMarket m
    ON m.MarketSegment = s.market_segment
   AND m.DistributionChannel = s.distribution_channel
   AND m.Agent = COALESCE(s.agent, 'Unknown')
   AND m.Company = COALESCE(s.company, 'Unknown')

LEFT JOIN dw.DimBookingProfile bp
    ON bp.MealType = s.meal
   AND bp.DepositType = s.deposit_type

LEFT JOIN dw.DimReservationStatus rs
    ON rs.ReservationStatus = s.reservation_status;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.8 � Load FactBooking

   Purpose:
      - Load cleaned and transformed booking records from
        staging into the dimensional warehouse fact table
      - Resolve dimension surrogate keys
      - Load booking measures and derived attributes
      - Preserve one fact row per source booking record

   Grain:One row in FactBooking = One source booking record
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO dw.FactBooking
(
    ArrivalDateKey,
    ReservationStatusDateKey,
    HotelKey,
    CustomerKey,
    RoomKey,
    MarketKey,
    BookingProfileKey,
    StatusKey,

    BookingCount,
    IsCanceled,
    LeadTime,
    WeekendNights,
    WeekNights,
    TotalStayNights,
    Adults,
    Children,
    Babies,
    TotalGuests,
    PreviousCancellations,
    PreviousBookingsNotCanceled,
    BookingChanges,
    DaysInWaitingList,
    ADR,
    RequiredCarParkingSpaces,
    TotalSpecialRequests
)

SELECT
    arrivalDate.DateKey,
    statusDate.DateKey,
    h.HotelKey,
    c.CustomerKey,
    r.RoomKey,
    m.MarketKey,
    bp.BookingProfileKey,
    rs.StatusKey,

    s.booking_count,
    s.is_canceled,
    s.lead_time,
    s.stays_in_weekend_nights,
    s.stays_in_week_nights,
    s.total_stay_nights,
    s.adults,
    s.children,
    s.babies,
    s.total_guests,
    s.previous_cancellations,
    s.previous_bookings_not_canceled,
    s.booking_changes,
    s.days_in_waiting_list,
    s.adr,
    s.required_car_parking_spaces,
    s.total_of_special_requests

FROM stg.HotelBooking s

INNER JOIN dw.DimDate arrivalDate
    ON arrivalDate.FullDate = s.arrival_date

INNER JOIN dw.DimDate statusDate
    ON statusDate.FullDate =
       TRY_CONVERT(DATE, s.reservation_status_date)

INNER JOIN dw.DimHotel h
    ON h.HotelType = s.hotel

INNER JOIN dw.DimCustomer c
    ON c.CustomerType = s.customer_type
   AND c.Country = COALESCE(s.country, 'Unknown')
   AND c.IsRepeatedGuest = s.is_repeated_guest

INNER JOIN dw.DimRoom r
    ON r.ReservedRoomType = s.reserved_room_type
   AND r.AssignedRoomType = s.assigned_room_type

INNER JOIN dw.DimMarket m
    ON m.MarketSegment = s.market_segment
   AND m.DistributionChannel = s.distribution_channel
   AND m.Agent = COALESCE(s.agent, 'Unknown')
   AND m.Company = COALESCE(s.company, 'Unknown')

INNER JOIN dw.DimBookingProfile bp
    ON bp.MealType = s.meal
   AND bp.DepositType = s.deposit_type

INNER JOIN dw.DimReservationStatus rs
    ON rs.ReservationStatus = s.reservation_status;
GO


/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.8.1 � Validate FactBooking Load

   Purpose:
      - Confirm all staging booking records were loaded
      - Validate the warehouse fact-table row count
      - Check basic booking and cancellation measures
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    COUNT(*) AS TotalFactRows,
    SUM(BookingCount) AS TotalBookings,
    SUM(IsCanceled) AS TotalCancellations,
    SUM(CASE
            WHEN IsCanceled = 0 THEN 1
            ELSE 0
        END) AS TotalNonCanceledBookings
FROM dw.FactBooking;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.9 � Final Fact Table Validation

   Purpose:
      - Validate key measures after FactBooking loading
      - Compare fact-table totals with staging data
      - Confirm that ETL preserved the source booking records
      - Identify any discrepancies before completing Task 5
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    'Staging' AS DataLayer,

    COUNT(*) AS TotalRows,

    SUM(booking_count) AS TotalBookings,

    SUM(is_canceled) AS TotalCancellations,

    SUM(CASE
            WHEN is_canceled = 0 THEN 1
            ELSE 0
        END) AS TotalNonCanceled,

    SUM(total_stay_nights) AS TotalStayNights,

    SUM(total_guests) AS TotalGuests,

    CAST(AVG(adr) AS DECIMAL(12,2)) AS AverageADR,

    CAST(AVG(CAST(lead_time AS DECIMAL(12,2)))
         AS DECIMAL(12,2)) AS AverageLeadTime

FROM stg.HotelBooking

UNION ALL

SELECT
    'Warehouse' AS DataLayer,

    COUNT(*) AS TotalRows,

    SUM(BookingCount) AS TotalBookings,

    SUM(IsCanceled) AS TotalCancellations,

    SUM(CASE
            WHEN IsCanceled = 0 THEN 1
            ELSE 0
        END) AS TotalNonCanceled,

    SUM(TotalStayNights) AS TotalStayNights,

    SUM(TotalGuests) AS TotalGuests,

    CAST(AVG(ADR) AS DECIMAL(12,2)) AS AverageADR,

    CAST(AVG(CAST(LeadTime AS DECIMAL(12,2)))
         AS DECIMAL(12,2)) AS AverageLeadTime

FROM dw.FactBooking;
GO
/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.9.1 � Final Dimension-Key Integrity Validation

   Purpose:
      - Confirm that every fact record contains valid
        dimension surrogate keys
      - Check for missing foreign-key values
      - Verify referential completeness of FactBooking
      - Provide final validation evidence for Task 5
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    SUM(CASE WHEN ArrivalDateKey IS NULL
             THEN 1 ELSE 0 END) AS MissingArrivalDateKey,

    SUM(CASE WHEN ReservationStatusDateKey IS NULL
             THEN 1 ELSE 0 END) AS MissingStatusDateKey,

    SUM(CASE WHEN HotelKey IS NULL
             THEN 1 ELSE 0 END) AS MissingHotelKey,

    SUM(CASE WHEN CustomerKey IS NULL
             THEN 1 ELSE 0 END) AS MissingCustomerKey,

    SUM(CASE WHEN RoomKey IS NULL
             THEN 1 ELSE 0 END) AS MissingRoomKey,

    SUM(CASE WHEN MarketKey IS NULL
             THEN 1 ELSE 0 END) AS MissingMarketKey,

    SUM(CASE WHEN BookingProfileKey IS NULL
             THEN 1 ELSE 0 END) AS MissingBookingProfileKey,

    SUM(CASE WHEN StatusKey IS NULL
             THEN 1 ELSE 0 END) AS MissingStatusKey

FROM dw.FactBooking;
GO
