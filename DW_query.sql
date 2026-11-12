-- ============================================================
-- How do borrowing behaviour and late-return rates differ across membership tiers? 
-- ============================================================
USE CA2DW2A0402;

SELECT
    M.MembershipTier,

    COUNT(*) AS TotalLoans,

    COUNT(DISTINCT M.MemberID) AS TotalMembers,

    ROUND(
        COUNT(*) * 1.0 / COUNT(DISTINCT M.MemberID),
        2
    ) AS AverageLoansPerMember,

    ROUND(
        AVG(F.LoanDuration),
        2
    ) AS AverageLoanDurationDays,

    SUM(
        CASE
            WHEN F.WasLate = 1 THEN 1
            ELSE 0
        END
    ) AS TotalLateLoans,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN F.WasLate = 1 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS LateReturnRatePercent

FROM FactLoan AS F

INNER JOIN DimMember AS M
    ON F.MemberKey = M.MemberKey

GROUP BY
    M.MembershipTier

ORDER BY
    TotalLoans DESC;

-- ============================================================
-- How does loan-processing workload vary across departments and employment types?   
-- ============================================================ 
USE CA2DW2A0402;
SELECT
    S.Department,
    S.EmploymentType,
    COUNT(*) AS TotalLoansProcessed,
    COUNT(DISTINCT S.StaffID) AS NumberOfStaff,
    ROUND(
        COUNT(*) * 1.0 / COUNT(DISTINCT S.StaffID),
        2
    ) AS AverageLoansPerStaff

FROM FactLoan F
JOIN DimStaff S
    ON F.StaffKey = S.StaffKey

GROUP BY
    S.Department,
    S.EmploymentType

ORDER BY
    S.Department DESC,
    S.EmploymentType DESC;
    
-- ============================================================
-- Which books have the highest borrowing frequency, and what are their genres and minimum membership-tier requirements?
-- ============================================================
use ca2dw2a0402;

SELECT
    B.Title,
    B.Genre,
    B.MinimumMembershipTier,
    COUNT(*) AS TotalLoans
FROM FactLoan F
JOIN DimBook B
    ON F.BookKey = B.BookKey
GROUP BY
    B.BookKey,
    B.Title,
    B.Genre,
    B.MinimumMembershipTier
ORDER BY TotalLoans DESC
LIMIT 10;

-- ============================================================
-- Which combinations of book genre and member age group have the highest average loan duration?
-- ============================================================
SELECT
    B.Genre,
    M.AgeGroup,
    ROUND(AVG(F.LoanDuration), 2) AS AverageLoanDuration
FROM FactLoan F
INNER JOIN DimBook B
    ON F.BookKey = B.BookKey
INNER JOIN DimMember M
    ON F.MemberKey = M.MemberKey
GROUP BY
    B.Genre,
    M.AgeGroup
ORDER BY
    AverageLoanDuration DESC
LIMIT 10;

-- ============================================================
-- Which member registration cohorts demonstrate the highest borrowing activity and late-return rate?
-- ============================================================ 
use ca2dw2a0402;

SELECT
    YEAR(M.RegistrationDate) AS RegistrationCohort,
    COUNT(DISTINCT M.MemberKey) AS NumberOfMembers,
    COUNT(F.FactLoanKey) AS TotalLoans,

    ROUND(
        COUNT(F.FactLoanKey)
        / NULLIF(COUNT(DISTINCT M.MemberKey), 0),
        2
    ) AS AverageLoansPerMember,

    SUM(IF(F.WasLate = 1, 1, 0)) AS LateLoans,

    ROUND(
        100.0 * SUM(IF(F.WasLate = 1, 1, 0))
        / NULLIF(COUNT(F.WasLate), 0),
        2
    ) AS LateReturnRatePercentage

FROM DimMember M
LEFT JOIN FactLoan F
    ON M.MemberKey = F.MemberKey

GROUP BY YEAR(M.RegistrationDate)

ORDER BY LateReturnRatePercentage DESC;

-- ============================================================
-- How do borrowing patterns differ between weekdays and weekends across different book genres?
-- ============================================================ 
USE ca2dw2a0402;

WITH DayCounts AS (
    SELECT
        SUM(IF(D.IsWeekend = 0, 1, 0)) AS NumberOfWeekdays,
        SUM(IF(D.IsWeekend = 1, 1, 0)) AS NumberOfWeekendDays

    FROM DimDate D

    JOIN (
        SELECT
            MIN(D1.FullDate) AS EarliestBorrowDate,
            MAX(D1.FullDate) AS LatestBorrowDate

        FROM FactLoan F1

        JOIN DimDate D1
            ON F1.BorrowDateKey = D1.DateKey
    ) AS DateRange

        ON D.FullDate BETWEEN
           DateRange.EarliestBorrowDate
           AND DateRange.LatestBorrowDate
),

GenreBorrowing AS (
    SELECT
        B.Genre,

        SUM(IF(D.IsWeekend = 0, 1, 0)) AS WeekdayLoans,

        SUM(IF(D.IsWeekend = 1, 1, 0)) AS WeekendLoans,

        C.NumberOfWeekdays,
        C.NumberOfWeekendDays

    FROM FactLoan F

    JOIN DimBook B
        ON F.BookKey = B.BookKey

    JOIN DimDate D
        ON F.BorrowDateKey = D.DateKey

    CROSS JOIN DayCounts C

    GROUP BY
        B.Genre,
        C.NumberOfWeekdays,
        C.NumberOfWeekendDays
)

SELECT
    Genre,
    WeekdayLoans,
    WeekendLoans,

    ROUND(
        WeekdayLoans /
        NULLIF(NumberOfWeekdays, 0),
        2
    ) AS AverageWeekdayLoansPerDay,

    ROUND(
        WeekendLoans /
        NULLIF(NumberOfWeekendDays, 0),
        2
    ) AS AverageWeekendLoansPerDay,

    ROUND(
        100.0 * WeekdayLoans /
        NULLIF(WeekdayLoans + WeekendLoans, 0),
        2
    ) AS WeekdaySharePercentage,

    ROUND(
        100.0 * WeekendLoans /
        NULLIF(WeekdayLoans + WeekendLoans, 0),
        2
    ) AS WeekendSharePercentage

FROM GenreBorrowing

ORDER BY
    AverageWeekendLoansPerDay DESC;