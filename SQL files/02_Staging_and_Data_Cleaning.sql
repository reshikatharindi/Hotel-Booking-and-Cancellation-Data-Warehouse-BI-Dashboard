-- ============================================================================
-- 02_Staging_and_Data_Cleaning.sql
-- Staging load, data profiling, data-quality review, cleaning, and derived columns.
-- ============================================================================

/* ============================================================
 
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.3.1 � Check Staging Table Before Transformation

   Purpose:- Confirm that the typed staging table is empty
        before loading transformed source records.
   ============================================================ */

USE HotelBookingDW;
GO

SELECT COUNT(*) AS CurrentStagingRows
FROM stg.HotelBooking;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.3.2 � Transform and Load Raw Data into Staging

   Purpose:
      - Transfer raw imported data into the typed staging table
      - Convert text values into appropriate SQL data types
      - Convert 'NA' and 'NULL' markers into SQL NULL
      - Remove leading/trailing spaces from text attributes
   ============================================================ */

USE HotelBookingDW;
GO

INSERT INTO stg.HotelBooking
(
    hotel,
    is_canceled,
    lead_time,
    arrival_date_year,
    arrival_date_month,
    arrival_date_week_number,
    arrival_date_day_of_month,
    stays_in_weekend_nights,
    stays_in_week_nights,
    adults,
    children,
    babies,
    meal,
    country,
    market_segment,
    distribution_channel,
    is_repeated_guest,
    previous_cancellations,
    previous_bookings_not_canceled,
    reserved_room_type,
    assigned_room_type,
    booking_changes,
    deposit_type,
    agent,
    company,
    days_in_waiting_list,
    customer_type,
    adr,
    required_car_parking_spaces,
    total_of_special_requests,
    reservation_status,
    reservation_status_date
)
SELECT
    -- Text cleansing
    NULLIF(LTRIM(RTRIM(hotel)), 'NULL'),

    -- Numeric conversions
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(is_canceled)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(lead_time)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(arrival_date_year)), 'NULL')),

    NULLIF(LTRIM(RTRIM(arrival_date_month)), 'NULL'),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(arrival_date_week_number)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(arrival_date_day_of_month)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(stays_in_weekend_nights)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(stays_in_week_nights)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(adults)), 'NULL')),

    -- children contains the source missing-value marker 'NA'
    TRY_CONVERT(
        DECIMAL(10,2),
        NULLIF(
            NULLIF(LTRIM(RTRIM(children)), 'NA'),
            'NULL'
        )
    ),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(babies)), 'NULL')),

    NULLIF(LTRIM(RTRIM(meal)), 'NULL'),

    -- Convert textual NULL marker into actual SQL NULL
    NULLIF(LTRIM(RTRIM(country)), 'NULL'),

    NULLIF(LTRIM(RTRIM(market_segment)), 'NULL'),
    NULLIF(LTRIM(RTRIM(distribution_channel)), 'NULL'),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(is_repeated_guest)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(previous_cancellations)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(previous_bookings_not_canceled)), 'NULL')),

    NULLIF(LTRIM(RTRIM(reserved_room_type)), 'NULL'),
    NULLIF(LTRIM(RTRIM(assigned_room_type)), 'NULL'),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(booking_changes)), 'NULL')),

    NULLIF(LTRIM(RTRIM(deposit_type)), 'NULL'),

    -- agent and company contain textual NULL markers
    NULLIF(LTRIM(RTRIM(agent)), 'NULL'),
    NULLIF(LTRIM(RTRIM(company)), 'NULL'),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(days_in_waiting_list)), 'NULL')),

    NULLIF(LTRIM(RTRIM(customer_type)), 'NULL'),

    TRY_CONVERT(
        DECIMAL(12,2),
        NULLIF(LTRIM(RTRIM(adr)), 'NULL')
    ),

    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(required_car_parking_spaces)), 'NULL')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(total_of_special_requests)), 'NULL')),

    NULLIF(LTRIM(RTRIM(reservation_status)), 'NULL'),

    -- Keep as text at this staging stage; date conversion follows later
    NULLIF(LTRIM(RTRIM(reservation_status_date)), 'NULL')

FROM dbo.HotelBooking_RawImport;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.3.3 � Validate Staging Load

   Purpose:
      - Confirm all raw records reached the staging layer
      - Confirm missing-value markers were transformed to SQL NULL
   ============================================================ */

SELECT COUNT(*) AS StagingRowCount
FROM stg.HotelBooking;

SELECT
    SUM(CASE WHEN children IS NULL THEN 1 ELSE 0 END) AS MissingChildren,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS MissingCountry,
    SUM(CASE WHEN agent IS NULL THEN 1 ELSE 0 END) AS MissingAgent,
    SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END) AS MissingCompany
FROM stg.HotelBooking;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.1 � Data Quality Validation

   Purpose:
      - Identify suspicious or invalid numerical values
      - Check business-rule inconsistencies before cleansing
      - Avoid deleting or modifying records without evidence
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    -- Bookings with no guests
    SUM(CASE
        WHEN COALESCE(adults, 0)
           + COALESCE(children, 0)
           + COALESCE(babies, 0) = 0
        THEN 1 ELSE 0
    END) AS ZeroGuestBookings,

    -- Negative ADR values
    SUM(CASE
        WHEN adr < 0
        THEN 1 ELSE 0
    END) AS NegativeADR,

    -- Zero ADR values
    SUM(CASE
        WHEN adr = 0
        THEN 1 ELSE 0
    END) AS ZeroADR,

    -- Negative lead time
    SUM(CASE
        WHEN lead_time < 0
        THEN 1 ELSE 0
    END) AS NegativeLeadTime,

    -- Bookings with no overnight stay
    SUM(CASE
        WHEN COALESCE(stays_in_weekend_nights, 0)
           + COALESCE(stays_in_week_nights, 0) = 0
        THEN 1 ELSE 0
    END) AS ZeroNightBookings,

    -- Invalid cancellation indicator
    SUM(CASE
        WHEN is_canceled NOT IN (0, 1)
        THEN 1 ELSE 0
    END) AS InvalidCancellationFlag,

    -- Invalid repeated guest indicator
    SUM(CASE
        WHEN is_repeated_guest NOT IN (0, 1)
        THEN 1 ELSE 0
    END) AS InvalidRepeatedGuestFlag

FROM stg.HotelBooking;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.2 � Investigate Zero-Guest Bookings

   Purpose:
      - Examine bookings where the total number of guests is zero
      - Determine whether these records should be retained,
        corrected, or excluded during ETL
      - Avoid removing records without investigation
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    hotel,
    is_canceled,
    lead_time,
    arrival_date_year,
    arrival_date_month,
    arrival_date_day_of_month,
    adults,
    children,
    babies,
    stays_in_weekend_nights,
    stays_in_week_nights,
    adr,
    market_segment,
    distribution_channel,
    customer_type,
    reservation_status
FROM stg.HotelBooking
WHERE
    COALESCE(adults, 0)
  + COALESCE(children, 0)
  + COALESCE(babies, 0) = 0
ORDER BY
    arrival_date_year,
    arrival_date_month,
    arrival_date_day_of_month;

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.2 � Summarize Zero-Guest Bookings

   Purpose:
      - Determine how zero-guest bookings are distributed
        between cancelled and non-cancelled reservations
   ============================================================ */

SELECT
    is_canceled,
    reservation_status,
    COUNT(*) AS NumberOfBookings
FROM stg.HotelBooking
WHERE
    COALESCE(adults, 0)
  + COALESCE(children, 0)
  + COALESCE(babies, 0) = 0
GROUP BY
    is_canceled,
    reservation_status
ORDER BY
    is_canceled,
    reservation_status;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.3 � Investigate Negative ADR

   Purpose:
      - Inspect the single booking with a negative ADR value
      - Determine whether the value represents an anomaly
      - Establish an appropriate ETL treatment before loading
        the dimensional warehouse
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    hotel,
    is_canceled,
    lead_time,
    arrival_date_year,
    arrival_date_month,
    arrival_date_day_of_month,
    adults,
    children,
    babies,
    stays_in_weekend_nights,
    stays_in_week_nights,
    adr,
    market_segment,
    distribution_channel,
    deposit_type,
    customer_type,
    reservation_status
FROM stg.HotelBooking
WHERE adr < 0;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.4 � Investigate Zero ADR Records

   Purpose:
      - Analyze bookings where ADR is zero
      - Determine whether zero ADR occurs in cancelled,
        no-show, or completed bookings
      - Avoid incorrectly treating all zero ADR values
        as data errors
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    is_canceled,
    reservation_status,
    COUNT(*) AS NumberOfBookings
FROM stg.HotelBooking
WHERE adr = 0
GROUP BY
    is_canceled,
    reservation_status
ORDER BY
    is_canceled,
    reservation_status;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.5 � Investigate Zero-Night Bookings

   Purpose:
      - Analyze bookings with zero recorded stay nights
      - Determine their reservation status
      - Decide whether these records should be retained
        during dimensional warehouse loading
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    is_canceled,
    reservation_status,
    COUNT(*) AS NumberOfBookings
FROM stg.HotelBooking
WHERE
    COALESCE(stays_in_weekend_nights, 0)
  + COALESCE(stays_in_week_nights, 0) = 0
GROUP BY
    is_canceled,
    reservation_status
ORDER BY
    is_canceled,
    reservation_status;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.6 � Validate Arrival Dates

   Purpose:
      - Construct arrival dates from Year, Month and Day fields
      - Identify records that cannot form a valid date
      - Prepare the data for the Date Dimension
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    COUNT(*) AS InvalidArrivalDates
FROM stg.HotelBooking
WHERE TRY_CONVERT(
    DATE,
    CONCAT(
        arrival_date_year, '-',
        CASE arrival_date_month
            WHEN 'January'   THEN '01'
            WHEN 'February'  THEN '02'
            WHEN 'March'     THEN '03'
            WHEN 'April'     THEN '04'
            WHEN 'May'       THEN '05'
            WHEN 'June'      THEN '06'
            WHEN 'July'      THEN '07'
            WHEN 'August'    THEN '08'
            WHEN 'September' THEN '09'
            WHEN 'October'   THEN '10'
            WHEN 'November'  THEN '11'
            WHEN 'December'  THEN '12'
        END,
        '-',
        RIGHT('0' + CAST(arrival_date_day_of_month AS VARCHAR(2)), 2)
    )
) IS NULL;



/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.7 � Validate Reservation Status Dates

   Purpose:
      - Check whether reservation_status_date can be converted
        from staging text into a proper SQL DATE
      - Identify missing or invalid status dates
      - Prepare the field for dimensional warehouse loading
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    COUNT(*) AS InvalidReservationStatusDates
FROM stg.HotelBooking
WHERE TRY_CONVERT(DATE, reservation_status_date) IS NULL;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.8 � Validate Categorical Values

   Purpose:
      - Inspect distinct values in important categorical fields
      - Identify inconsistent spellings or unexpected categories
      - Determine whether category standardization is required
        before dimensional warehouse loading
   ============================================================ */

USE HotelBookingDW;
GO

-- Hotel categories
SELECT hotel, COUNT(*) AS Frequency
FROM stg.HotelBooking
GROUP BY hotel
ORDER BY hotel;

-- Meal categories
SELECT meal, COUNT(*) AS Frequency
FROM stg.HotelBooking
GROUP BY meal
ORDER BY meal;

-- Market segment categories
SELECT market_segment, COUNT(*) AS Frequency
FROM stg.HotelBooking
GROUP BY market_segment
ORDER BY market_segment;

-- Distribution channel categories
SELECT distribution_channel, COUNT(*) AS Frequency
FROM stg.HotelBooking
GROUP BY distribution_channel
ORDER BY distribution_channel;

-- Deposit type categories
SELECT deposit_type, COUNT(*) AS Frequency
FROM stg.HotelBooking
GROUP BY deposit_type
ORDER BY deposit_type;

-- Customer type categories
SELECT customer_type, COUNT(*) AS Frequency
FROM stg.HotelBooking
GROUP BY customer_type
ORDER BY customer_type;

-- Reservation status categories
SELECT reservation_status, COUNT(*) AS Frequency
FROM stg.HotelBooking
GROUP BY reservation_status
ORDER BY reservation_status;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.9 � Exact Duplicate Investigation

   Purpose:
      - Identify the number of exact duplicate records
        in the staging dataset
      - Investigate duplicates before deciding whether they
        should be removed or retained
      - Avoid deleting potentially valid hotel bookings because
        the source dataset has no unique Booking ID
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    COUNT(*) AS TotalRows,
    COUNT(*) - COUNT(DISTINCT RowSignature) AS ExactDuplicateRows
FROM
(
    SELECT CONCAT_WS('|',
        hotel,
        is_canceled,
        lead_time,
        arrival_date_year,
        arrival_date_month,
        arrival_date_week_number,
        arrival_date_day_of_month,
        stays_in_weekend_nights,
        stays_in_week_nights,
        adults,
        children,
        babies,
        meal,
        country,
        market_segment,
        distribution_channel,
        is_repeated_guest,
        previous_cancellations,
        previous_bookings_not_canceled,
        reserved_room_type,
        assigned_room_type,
        booking_changes,
        deposit_type,
        agent,
        company,
        days_in_waiting_list,
        customer_type,
        adr,
        required_car_parking_spaces,
        total_of_special_requests,
        reservation_status,
        reservation_status_date
    ) AS RowSignature
    FROM stg.HotelBooking
) AS DuplicateCheck;
GO




/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.10 � Investigate Exact Duplicate Frequency

   Purpose:
      - Determine how frequently identical booking records occur
      - Identify whether duplicate-looking records occur twice
        or repeatedly
      - Support an evidence-based decision on whether duplicate
        records should be retained or removed
      - Avoid deleting potentially legitimate bookings because
        the source does not contain a unique Booking ID
   ============================================================ */

USE HotelBookingDW;
GO

WITH DuplicateGroups AS
(
    SELECT
        hotel,
        is_canceled,
        lead_time,
        arrival_date_year,
        arrival_date_month,
        arrival_date_week_number,
        arrival_date_day_of_month,
        stays_in_weekend_nights,
        stays_in_week_nights,
        adults,
        children,
        babies,
        meal,
        country,
        market_segment,
        distribution_channel,
        is_repeated_guest,
        previous_cancellations,
        previous_bookings_not_canceled,
        reserved_room_type,
        assigned_room_type,
        booking_changes,
        deposit_type,
        agent,
        company,
        days_in_waiting_list,
        customer_type,
        adr,
        required_car_parking_spaces,
        total_of_special_requests,
        reservation_status,
        reservation_status_date,

        COUNT(*) AS OccurrenceCount

    FROM stg.HotelBooking

    GROUP BY
        hotel,
        is_canceled,
        lead_time,
        arrival_date_year,
        arrival_date_month,
        arrival_date_week_number,
        arrival_date_day_of_month,
        stays_in_weekend_nights,
        stays_in_week_nights,
        adults,
        children,
        babies,
        meal,
        country,
        market_segment,
        distribution_channel,
        is_repeated_guest,
        previous_cancellations,
        previous_bookings_not_canceled,
        reserved_room_type,
        assigned_room_type,
        booking_changes,
        deposit_type,
        agent,
        company,
        days_in_waiting_list,
        customer_type,
        adr,
        required_car_parking_spaces,
        total_of_special_requests,
        reservation_status,
        reservation_status_date

    HAVING COUNT(*) > 1
)

SELECT
    OccurrenceCount,
    COUNT(*) AS NumberOfDuplicateGroups,
    SUM(OccurrenceCount) AS TotalRowsInGroups
FROM DuplicateGroups
GROUP BY OccurrenceCount
ORDER BY OccurrenceCount;
GO

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.4.11 � Validate Missing Values Across Staging Data

   Purpose:
      - Check missing values across all important attributes
      - Confirm whether missing data is limited to the fields
        already identified during data profiling
      - Support missing-value treatment decisions before
        dimensional warehouse loading
   ============================================================ */

USE HotelBookingDW;
GO

SELECT
    SUM(CASE WHEN hotel IS NULL THEN 1 ELSE 0 END) AS HotelMissing,
    SUM(CASE WHEN is_canceled IS NULL THEN 1 ELSE 0 END) AS IsCanceledMissing,
    SUM(CASE WHEN lead_time IS NULL THEN 1 ELSE 0 END) AS LeadTimeMissing,
    SUM(CASE WHEN arrival_date_year IS NULL THEN 1 ELSE 0 END) AS YearMissing,
    SUM(CASE WHEN arrival_date_month IS NULL THEN 1 ELSE 0 END) AS MonthMissing,
    SUM(CASE WHEN arrival_date_day_of_month IS NULL THEN 1 ELSE 0 END) AS DayMissing,

    SUM(CASE WHEN stays_in_weekend_nights IS NULL THEN 1 ELSE 0 END) AS WeekendNightsMissing,
    SUM(CASE WHEN stays_in_week_nights IS NULL THEN 1 ELSE 0 END) AS WeekNightsMissing,

    SUM(CASE WHEN adults IS NULL THEN 1 ELSE 0 END) AS AdultsMissing,
    SUM(CASE WHEN children IS NULL THEN 1 ELSE 0 END) AS ChildrenMissing,
    SUM(CASE WHEN babies IS NULL THEN 1 ELSE 0 END) AS BabiesMissing,

    SUM(CASE WHEN meal IS NULL THEN 1 ELSE 0 END) AS MealMissing,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS CountryMissing,
    SUM(CASE WHEN market_segment IS NULL THEN 1 ELSE 0 END) AS MarketSegmentMissing,
    SUM(CASE WHEN distribution_channel IS NULL THEN 1 ELSE 0 END) AS DistributionChannelMissing,

    SUM(CASE WHEN is_repeated_guest IS NULL THEN 1 ELSE 0 END) AS RepeatedGuestMissing,

    SUM(CASE WHEN reserved_room_type IS NULL THEN 1 ELSE 0 END) AS ReservedRoomMissing,
    SUM(CASE WHEN assigned_room_type IS NULL THEN 1 ELSE 0 END) AS AssignedRoomMissing,

    SUM(CASE WHEN deposit_type IS NULL THEN 1 ELSE 0 END) AS DepositTypeMissing,
    SUM(CASE WHEN agent IS NULL THEN 1 ELSE 0 END) AS AgentMissing,
    SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END) AS CompanyMissing,

    SUM(CASE WHEN customer_type IS NULL THEN 1 ELSE 0 END) AS CustomerTypeMissing,
    SUM(CASE WHEN adr IS NULL THEN 1 ELSE 0 END) AS ADRMissing,

    SUM(CASE WHEN reservation_status IS NULL THEN 1 ELSE 0 END) AS ReservationStatusMissing,
    SUM(CASE WHEN reservation_status_date IS NULL THEN 1 ELSE 0 END) AS ReservationStatusDateMissing

FROM stg.HotelBooking;
GO

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.5.1 � Missing Value Treatment for Children

   Purpose:
      - Replace the 4 missing children values with 0
      - Prevent NULL values when calculating TotalGuests
      - Prepare the data for dimensional warehouse loading

   ETL Assumption:
      - Missing children values are treated as 0 because only
        4 records are affected and guest-count calculations
        require a usable numeric value.
   ============================================================ */

USE HotelBookingDW;
GO

-- Check number of records before treatment
SELECT COUNT(*) AS MissingChildrenBefore
FROM stg.HotelBooking
WHERE children IS NULL;
GO

-- Replace missing children values with 0
UPDATE stg.HotelBooking
SET children = 0
WHERE children IS NULL;
GO

-- Validate the treatment
SELECT COUNT(*) AS MissingChildrenAfter
FROM stg.HotelBooking
WHERE children IS NULL;
GO

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.5.2 � Add Derived Attributes to Staging Table

   Purpose:
      - Add analytical attributes required by the warehouse
      - Prepare fields for FactBooking and Power BI analysis

   Derived Attributes:
      ArrivalDate      = Year + Month + Day
      TotalStayNights  = Weekend Nights + Week Nights
      TotalGuests      = Adults + Children + Babies
      BookingCount     = 1 per source booking record
   ============================================================ */

USE HotelBookingDW;
GO

ALTER TABLE stg.HotelBooking
ADD
    arrival_date DATE NULL,
    total_stay_nights INT NULL,
    total_guests DECIMAL(10,2) NULL,
    booking_count INT NULL;
GO

/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.5.2 � Validate Derived Column Creation
   ============================================================ */

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'HotelBooking'
  AND COLUMN_NAME IN
  (
      'arrival_date',
      'total_stay_nights',
      'total_guests',
      'booking_count'
  )
ORDER BY COLUMN_NAME;

/* ============================================================

   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.5.3 � Populate Derived Attributes

   Purpose:
      - Construct a proper Arrival Date
      - Calculate total length of stay
      - Calculate total number of guests
      - Assign BookingCount = 1 for aggregation

   Derived Attributes:
      arrival_date       = Year + Month + Day
      total_stay_nights  = Weekend Nights + Week Nights
      total_guests       = Adults + Children + Babies
      booking_count      = 1
   ============================================================ */

USE HotelBookingDW;
GO

UPDATE stg.HotelBooking
SET
    -- Construct proper arrival date
    arrival_date =
        TRY_CONVERT(
            DATE,
            CONCAT(
                arrival_date_year, '-',
                CASE arrival_date_month
                    WHEN 'January'   THEN '01'
                    WHEN 'February'  THEN '02'
                    WHEN 'March'     THEN '03'
                    WHEN 'April'     THEN '04'
                    WHEN 'May'       THEN '05'
                    WHEN 'June'      THEN '06'
                    WHEN 'July'      THEN '07'
                    WHEN 'August'    THEN '08'
                    WHEN 'September' THEN '09'
                    WHEN 'October'   THEN '10'
                    WHEN 'November'  THEN '11'
                    WHEN 'December'  THEN '12'
                END,
                '-',
                RIGHT(
                    '0' + CAST(arrival_date_day_of_month AS VARCHAR(2)),
                    2
                )
            )
        ),

    -- Total length of stay
    total_stay_nights =
        COALESCE(stays_in_weekend_nights, 0)
        + COALESCE(stays_in_week_nights, 0),

    -- Total number of guests
    total_guests =
        COALESCE(adults, 0)
        + COALESCE(children, 0)
        + COALESCE(babies, 0),

    -- Each source row represents one booking record
    booking_count = 1;
GO




/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.5.4 � Validate Derived Attributes

   Purpose:
      - Confirm derived attributes were populated successfully
      - Check that no unexpected NULL values were produced
   ============================================================ */

SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN arrival_date IS NULL
             THEN 1 ELSE 0 END) AS MissingArrivalDate,

    SUM(CASE WHEN total_stay_nights IS NULL
             THEN 1 ELSE 0 END) AS MissingTotalStayNights,

    SUM(CASE WHEN total_guests IS NULL
             THEN 1 ELSE 0 END) AS MissingTotalGuests,

    SUM(CASE WHEN booking_count IS NULL
             THEN 1 ELSE 0 END) AS MissingBookingCount,

    SUM(booking_count) AS TotalBookingCount

FROM stg.HotelBooking;
GO



/* ============================================================
   TASK 5 � ETL PROCESS DEVELOPMENT
   Step 5.5.4 � Preview Derived Attributes
   ============================================================ */

SELECT TOP (10)
    hotel,
    arrival_date,
    adults,
    children,
    babies,
    total_guests,
    stays_in_weekend_nights,
    stays_in_week_nights,
    total_stay_nights,
    booking_count,
    adr
FROM stg.HotelBooking;
GO
