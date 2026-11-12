USE CA2DW2A0402;

-- =====================================================
-- Clear Existing Data from Final Tables
-- =====================================================
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE FactLoan;
TRUNCATE TABLE DimDate;
TRUNCATE TABLE DimStaff;
TRUNCATE TABLE DimBook;
TRUNCATE TABLE DimMember;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- load DimMember from ca22a0402.Member & ca22a0402.MembershipTier
-- =====================================================
INSERT INTO DimMember (
    MemberID,
    Gender,
    Occupation,
    MembershipTier,
    AgeGroup,
    RegistrationDate
)
SELECT
    M.MemberID,
    M.Gender,
    M.Occupation,
    MT.TierName,

    CASE
        WHEN TIMESTAMPDIFF(YEAR, M.DOB, CURDATE()) < 18
            THEN 'Under 18'

        WHEN TIMESTAMPDIFF(YEAR, M.DOB, CURDATE()) BETWEEN 18 AND 25
            THEN '18-25'

        WHEN TIMESTAMPDIFF(YEAR, M.DOB, CURDATE()) BETWEEN 26 AND 40
            THEN '26-40'

        WHEN TIMESTAMPDIFF(YEAR, M.DOB, CURDATE()) BETWEEN 41 AND 60
            THEN '41-60'

        ELSE 'Above 60'
    END AS AgeGroup,

    DATE(M.RegistrationDatetime) AS RegistrationDate

FROM ca22a0402.Member M

INNER JOIN ca22a0402.MembershipTier MT
    ON M.TierID = MT.TierID;
    
-- =====================================================
-- load DimBook from ca22a0402.Book & ca22a0402.MembershipTier
-- =====================================================
INSERT INTO DimBook (
    BookID,
    Title,
    Genre,
    Author,
    MinimumMembershipTier
)
SELECT
    B.BookID,
    B.Title,
    B.Genre,
    B.Author,
    MT.TierName

FROM ca22a0402.Book B

INNER JOIN ca22a0402.MembershipTier MT
    ON B.MinTierID = MT.TierID;
    
-- =====================================================
-- load DimStaff from ca22a0402.Staff
-- =====================================================
INSERT INTO DimStaff (
    StaffID,
    Gender,
    EmploymentType,
    Department,
    StartDate
)
SELECT
    StaffID,
    Gender,
    EmploymentType,
    Department,
    StartDate
FROM ca22a0402.Staff;

-- =====================================================
-- load DimDate 
-- =====================================================
SET SESSION cte_max_recursion_depth = 10000;

INSERT INTO DimDate (
    FullDate,
    DayOfMonth,
    DayOfWeekNumber,
    DayOfWeekName,
    MonthNumber,
    MonthName,
    Quarter,
    Year,
    IsWeekend
)
WITH RECURSIVE DateRange AS (
    SELECT
        LEAST(
            MIN(DATE(StartDatetime)),
            MIN(DueDate),
            MIN(DATE(ReturnDatetime))
        ) AS FullDate
    FROM ca22a0402.Loan
    WHERE ReturnDatetime IS NOT NULL

    UNION ALL

    SELECT
        DATE_ADD(FullDate, INTERVAL 1 DAY)
    FROM DateRange
    WHERE FullDate < (
        SELECT
            GREATEST(
                MAX(DATE(StartDatetime)),
                MAX(DueDate),
                MAX(DATE(ReturnDatetime))
            )
        FROM ca22a0402.Loan
        WHERE ReturnDatetime IS NOT NULL
    )
)
SELECT
    FullDate,
    DAY(FullDate) AS DayOfMonth,
    DAYOFWEEK(FullDate) AS DayOfWeekNumber,
    DAYNAME(FullDate) AS DayOfWeekName,
    MONTH(FullDate) AS MonthNumber,
    MONTHNAME(FullDate) AS MonthName,
    QUARTER(FullDate) AS Quarter,
    YEAR(FullDate) AS Year,

    CASE
        WHEN DAYOFWEEK(FullDate) IN (1, 7)
            THEN TRUE
        ELSE FALSE
    END AS IsWeekend

FROM DateRange;

-- =====================================================
-- load FactLoan 
-- =====================================================
INSERT INTO FactLoan (
    MemberKey,
    BookKey,
    StaffKey,
    BorrowDateKey,
    LoanDuration,
    WasLate
)
SELECT
    DM.MemberKey,
    DB.BookKey,
    DS.StaffKey,
    BorrowDate.DateKey AS BorrowDateKey,

    DATEDIFF(
        DATE(L.ReturnDatetime),
        DATE(L.StartDatetime)
    ) AS LoanDuration,

    CASE
        WHEN DATE(L.ReturnDatetime) > L.DueDate
            THEN TRUE
        ELSE FALSE
    END AS WasLate

FROM ca22a0402.Loan L

INNER JOIN DimMember DM
    ON L.MemberID = DM.MemberID

INNER JOIN DimBook DB
    ON L.BookID = DB.BookID

INNER JOIN DimStaff DS
    ON L.StaffID = DS.StaffID

INNER JOIN DimDate BorrowDate
    ON DATE(L.StartDatetime) = BorrowDate.FullDate
    
WHERE L.ReturnDatetime IS NOT NULL;

-- =====================================================
-- Verification Queries
-- =====================================================

-- verification 1: count all dw tables
SELECT
    'DimMember' AS TableName,
    COUNT(*) AS RowCount
FROM DimMember

UNION ALL

SELECT
    'DimBook',
    COUNT(*)
FROM DimBook

UNION ALL

SELECT
    'DimStaff',
    COUNT(*)
FROM DimStaff

UNION ALL

SELECT
    'DimDate',
    COUNT(*)
FROM DimDate

UNION ALL

SELECT
    'FactLoan',
    COUNT(*)
FROM FactLoan;

-- verification 2: compare completed OLTP loans to FactLoan
SELECT
    (
        SELECT COUNT(*)
        FROM ca22a0402.Loan
        WHERE ReturnDatetime IS NOT NULL
    ) AS CompletedOLTPLoans,

    (
        SELECT COUNT(*)
        FROM FactLoan
    ) AS FactLoanRows;
    
-- verification 3: verify dimensions against source counts
SELECT
    (SELECT COUNT(*) FROM ca22a0402.Member) AS OLTPMembers,
    (SELECT COUNT(*) FROM DimMember) AS DWMembers,

    (SELECT COUNT(*) FROM ca22a0402.Book) AS OLTPBooks,
    (SELECT COUNT(*) FROM DimBook) AS DWBooks,

    (SELECT COUNT(*) FROM ca22a0402.Staff) AS OLTPStaff,
    (SELECT COUNT(*) FROM DimStaff) AS DWStaff;
    
-- verification 4: confirm got no negative loan durations
SELECT *
FROM FactLoan
WHERE LoanDuration < 0;

-- verification 5: verify late loans calculation
SELECT
    SUM(
        CASE
            WHEN DATE(ReturnDatetime) > DueDate THEN 1
            ELSE 0
        END
    ) AS OLTPLateLoans,

    (
        SELECT SUM(WasLate)
        FROM CA2DW2A0402.FactLoan
    ) AS DWLateLoans

FROM ca22a0402.Loan
WHERE ReturnDatetime IS NOT NULL;