-- =====================================================
-- CA2 STAGING AND DATA-CLEANING SCRIPT
-- =====================================================


-- =====================================================
-- 1. Create Main and Staging Schemas
-- =====================================================

CREATE SCHEMA IF NOT EXISTS `ca22a0402`;
CREATE SCHEMA IF NOT EXISTS `ca22a0402(stg)`;

USE `ca22a0402(stg)`;


-- =====================================================
-- 2. Staff Staging Table
-- =====================================================

DROP TABLE IF EXISTS StgStaff;

CREATE TABLE StgStaff (
    StaffID VARCHAR(50),
    StaffName VARCHAR(255),
    Gender VARCHAR(50),
    Contact VARCHAR(255),
    EmploymentType VARCHAR(100),
    StartDatetime VARCHAR(100),
    Department VARCHAR(255),
    DOB VARCHAR(100)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Staff.csv'
INTO TABLE StgStaff
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    StaffID,
    StaffName,
    Gender,
    Contact,
    EmploymentType,
    StartDatetime,
    Department,
    DOB
);


-- =====================================================
-- 3. Book Staging Table
-- =====================================================

DROP TABLE IF EXISTS StgBook;

CREATE TABLE StgBook (
    BookID VARCHAR(50),
    Title VARCHAR(500),
    Author VARCHAR(255),
    Genre VARCHAR(100),
    MinTierID VARCHAR(50)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Books.csv'
INTO TABLE StgBook
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    BookID,
    Title,
    Author,
    Genre,
    MinTierID
);


-- =====================================================
-- 4. Book Copy Staging Table
-- =====================================================

DROP TABLE IF EXISTS StgBookCopy;

CREATE TABLE StgBookCopy (
    BookID VARCHAR(50),
    CopySeqNo VARCHAR(50),
    Status VARCHAR(100)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/BookCopies.csv'
INTO TABLE StgBookCopy
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    BookID,
    CopySeqNo,
    Status
);


-- =====================================================
-- 5. Member Staging Table
-- =====================================================

DROP TABLE IF EXISTS StgMember;

CREATE TABLE StgMember (
    MemberID VARCHAR(50),
    FullName VARCHAR(255),
    ContactNo VARCHAR(100),
    Email VARCHAR(255),
    DateOfBirth VARCHAR(100),
    Gender VARCHAR(50),
    Occupation VARCHAR(255),
    RegistrationDatetime VARCHAR(100),
    TierID VARCHAR(50)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Members.csv'
INTO TABLE StgMember
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    MemberID,
    FullName,
    ContactNo,
    Email,
    DateOfBirth,
    Gender,
    Occupation,
    RegistrationDatetime,
    TierID
);


-- =====================================================
-- 6. Loan Staging Table
-- =====================================================

DROP TABLE IF EXISTS StgLoan;

CREATE TABLE StgLoan (
    MemberID VARCHAR(50),
    BookID VARCHAR(50),
    CopySeqNo VARCHAR(50),
    StaffID VARCHAR(50),
    LoanDatetime VARCHAR(100),
    DueDate VARCHAR(100),
    ReturnDatetime VARCHAR(100),
    LoanStatus VARCHAR(100)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Loans.csv'
INTO TABLE `ca22a0402(stg)`.StgLoan
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    MemberID,
    BookID,
    CopySeqNo,
    StaffID,
    LoanDatetime,
    DueDate,
    ReturnDatetime,
    @LoanStatusColumn8,
    @LoanStatusColumn9
)
SET LoanStatus =
    COALESCE(
        NULLIF(TRIM(@LoanStatusColumn8), ''),
        NULLIF(TRIM(@LoanStatusColumn9), ''),
        CASE
            WHEN NULLIF(TRIM(ReturnDatetime), '') IS NULL
                THEN 'OnLoan'
        END
    );

-- =====================================================
-- 7. Membership Tier Staging Table
-- =====================================================

DROP TABLE IF EXISTS StgMembershipTier;

CREATE TABLE StgMembershipTier (
    TierID VARCHAR(50),
    TierName VARCHAR(100),
    TierLevel VARCHAR(50),
    BorrowLimit VARCHAR(50)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MembershipTier.txt'
INTO TABLE `ca22a0402(stg)`.StgMembershipTier
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r'
IGNORE 1 LINES
(
    TierID,
    TierName,
    TierLevel,
    BorrowLimit
);


-- =====================================================
-- 8. Clear Existing Data from Final Tables
-- =====================================================

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE ca22a0402.Loan;
TRUNCATE TABLE ca22a0402.BookCopy;
TRUNCATE TABLE ca22a0402.Book;
TRUNCATE TABLE ca22a0402.Member;
TRUNCATE TABLE ca22a0402.Staff;
TRUNCATE TABLE ca22a0402.MembershipTier;

SET FOREIGN_KEY_CHECKS = 1;


-- =====================================================
-- 9. Insert Cleaned Membership Tier Data
-- =====================================================

INSERT INTO ca22a0402.MembershipTier (
    TierID,
    TierName,
    TierLevel,
    BorrowLimit
)
SELECT
    REPLACE(
        REPLACE(TRIM(TierID), '\r', ''),
        '﻿',
        ''
    ) AS TierID,

    REPLACE(
        REPLACE(TRIM(TierName), '\r', ''),
        '\n',
        ''
    ) AS TierName,

    CAST(
        REPLACE(
            REPLACE(TRIM(TierLevel), '\r', ''),
            '\n',
            ''
        ) AS UNSIGNED
    ) AS TierLevel,

    CAST(
        REPLACE(
            REPLACE(TRIM(BorrowLimit), '\r', ''),
            '\n',
            ''
        ) AS UNSIGNED
    ) AS BorrowLimit

FROM `ca22a0402(stg)`.StgMembershipTier;


-- =====================================================
-- 10. Insert Cleaned Staff Data
-- =====================================================

INSERT INTO ca22a0402.Staff (
    StaffID,
    Name,
    Contact,
    Gender,
    EmploymentType,
    StartDate,
    Department,
    DOB
)
SELECT
    R.StaffID,

    R.StaffName AS Name,

    NULLIF(R.Contact, '') AS Contact,

    CASE
        WHEN R.Gender IN ('male', 'm')
        THEN 'M'

        WHEN R.Gender IN ('female', 'f')
        THEN 'F'

        ELSE NULL
    END AS Gender,

    CASE
        WHEN LOWER(
            REPLACE(
                REPLACE(R.EmploymentType, '-', ''),
                ' ',
                ''
            )
        ) = 'fulltime'
        THEN 'Full-time'

        WHEN LOWER(
            REPLACE(
                REPLACE(R.EmploymentType, '-', ''),
                ' ',
                ''
            )
        ) = 'parttime'
        THEN 'Part-time'

        ELSE NULLIF(R.EmploymentType, '')
    END AS EmploymentType,

    CASE
        WHEN R.StartDatetime
             REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
        THEN STR_TO_DATE(
            LEFT(R.StartDatetime, 10),
            '%Y-%m-%d'
        )

        WHEN R.StartDatetime
             REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}'
        THEN STR_TO_DATE(
            SUBSTRING_INDEX(R.StartDatetime, ' ', 1),
            '%m/%d/%Y'
        )

        ELSE NULL
    END AS StartDate,

    NULLIF(R.Department, '') AS Department,

    CASE
        WHEN R.DOB REGEXP '^[0-9]+(\\.[0-9]+)?$'
        THEN DATE_ADD(
            '1899-12-30',
            INTERVAL CAST(R.DOB AS UNSIGNED) DAY
        )

        WHEN R.DOB
             REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(
            R.DOB,
            '%Y-%m-%d'
        )

        WHEN R.DOB
             REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
        THEN STR_TO_DATE(
            R.DOB,
            '%m/%d/%Y'
        )

        ELSE NULL
    END AS DOB

FROM (
    SELECT
        UPPER(
            REGEXP_REPLACE(
                TRIM(StaffID),
                '[^A-Za-z0-9]',
                ''
            )
        ) AS StaffID,

        TRIM(
            REPLACE(
                REPLACE(StaffName, '\r', ''),
                '\n',
                ''
            )
        ) AS StaffName,

        TRIM(
            REPLACE(
                REPLACE(Contact, '\r', ''),
                '\n',
                ''
            )
        ) AS Contact,

        LOWER(
            TRIM(
                REPLACE(
                    REPLACE(Gender, '\r', ''),
                    '\n',
                    ''
                )
            )
        ) AS Gender,

        TRIM(
            REPLACE(
                REPLACE(EmploymentType, '\r', ''),
                '\n',
                ''
            )
        ) AS EmploymentType,

        TRIM(
            REPLACE(
                REPLACE(StartDatetime, '\r', ''),
                '\n',
                ''
            )
        ) AS StartDatetime,

        TRIM(
            REPLACE(
                REPLACE(Department, '\r', ''),
                '\n',
                ''
            )
        ) AS Department,

        TRIM(
            REPLACE(
                REPLACE(DOB, '\r', ''),
                '\n',
                ''
            )
        ) AS DOB

    FROM `ca22a0402(stg)`.StgStaff
) AS R

WHERE R.StaffID <> 'STAFFID'
  AND R.StaffID <> '';


-- =====================================================
-- 11. Insert Cleaned Book Data
-- =====================================================

INSERT INTO ca22a0402.Book (
    BookID,
    Title,
    Author,
    Genre,
    MinTierID
)
SELECT
    R.BookID,
    R.Title,
    R.Author,
    R.Genre,
    R.MinTierID

FROM (
    SELECT
        UPPER(
            REGEXP_REPLACE(
                TRIM(BookID),
                '[^A-Za-z0-9]',
                ''
            )
        ) AS BookID,

        TRIM(
            REPLACE(
                REPLACE(Title, '\r', ''),
                '\n',
                ''
            )
        ) AS Title,

        TRIM(
            REPLACE(
                REPLACE(Author, '\r', ''),
                '\n',
                ''
            )
        ) AS Author,

        TRIM(
            REPLACE(
                REPLACE(Genre, '\r', ''),
                '\n',
                ''
            )
        ) AS Genre,

        UPPER(
            REGEXP_REPLACE(
                TRIM(MinTierID),
                '[^A-Za-z0-9]',
                ''
            )
        ) AS MinTierID

    FROM `ca22a0402(stg)`.StgBook
) AS R

INNER JOIN ca22a0402.MembershipTier MT
    ON R.MinTierID = MT.TierID

WHERE R.BookID <> 'BOOKID'
  AND R.BookID <> '';


-- =====================================================
-- 12. Insert Cleaned Book Copy Data
-- =====================================================

INSERT INTO ca22a0402.BookCopy (
    BookID,
    CopySeqNo,
    Status
)
SELECT
    R.BookID,
    R.CopySeqNo,
    R.Status

FROM (
    SELECT
        UPPER(
            REGEXP_REPLACE(
                TRIM(BookID),
                '[^A-Za-z0-9]',
                ''
            )
        ) AS BookID,

        CASE
            WHEN TRIM(
                REPLACE(CopySeqNo, '\r', '')
            ) REGEXP '^[0-9]+$'
            THEN CAST(
                TRIM(
                    REPLACE(CopySeqNo, '\r', '')
                ) AS UNSIGNED
            )

            ELSE NULL
        END AS CopySeqNo,

        CASE
            WHEN LOWER(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(TRIM(Status), '\r', ''),
                            '\n',
                            ''
                        ),
                        '-',
                        ''
                    ),
                    ' ',
                    ''
                )
            ) IN ('available', 'availble')
            THEN 'Available'

            WHEN LOWER(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(TRIM(Status), '\r', ''),
                            '\n',
                            ''
                        ),
                        '-',
                        ''
                    ),
                    ' ',
                    ''
                )
            ) = 'onloan'
            THEN 'On Loan'

            WHEN LOWER(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(TRIM(Status), '\r', ''),
                            '\n',
                            ''
                        ),
                        '-',
                        ''
                    ),
                    ' ',
                    ''
                )
            ) = 'lost'
            THEN 'Lost'

            ELSE NULL
        END AS Status

    FROM `ca22a0402(stg)`.StgBookCopy
) AS R

INNER JOIN ca22a0402.Book B
    ON R.BookID = B.BookID

WHERE R.BookID <> 'BOOKID'
  AND R.BookID <> ''
  AND R.CopySeqNo IS NOT NULL
  AND R.Status IS NOT NULL;


-- =====================================================
-- 13. Insert Cleaned Member Data
-- =====================================================

INSERT INTO ca22a0402.Member (
    MemberID,
    Name,
    Contact,
    DOB,
    Gender,
    Occupation,
    RegistrationDatetime,
    TierID
)
SELECT
    R.MemberID,

    R.FullName AS Name,

    CONCAT_WS(
        ' / ',
        NULLIF(R.ContactNo, ''),
        NULLIF(R.Email, '')
    ) AS Contact,

    CASE
        WHEN R.DateOfBirth
             REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(
            R.DateOfBirth,
            '%Y-%m-%d'
        )

        WHEN R.DateOfBirth
             REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
        THEN STR_TO_DATE(
            R.DateOfBirth,
            '%d/%m/%Y'
        )

        ELSE NULL
    END AS DOB,

    CASE
        WHEN LOWER(R.Gender) IN ('male', 'm')
        THEN 'M'

        WHEN LOWER(R.Gender) IN ('female', 'f')
        THEN 'F'

        ELSE NULL
    END AS Gender,

    NULLIF(R.Occupation, '') AS Occupation,

    CASE
        WHEN R.RegistrationDatetime
             REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
        THEN STR_TO_DATE(
            R.RegistrationDatetime,
            '%Y-%m-%d %H:%i:%s'
        )

        WHEN R.RegistrationDatetime
             REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$'
        THEN STR_TO_DATE(
            R.RegistrationDatetime,
            '%Y-%m-%d %H:%i'
        )

        WHEN R.RegistrationDatetime
             REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(
            R.RegistrationDatetime,
            '%Y-%m-%d'
        )

        WHEN R.RegistrationDatetime
             REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
        THEN STR_TO_DATE(
            R.RegistrationDatetime,
            '%d/%m/%Y %H:%i:%s'
        )

        WHEN R.RegistrationDatetime
             REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{2}:[0-9]{2}$'
        THEN STR_TO_DATE(
            R.RegistrationDatetime,
            '%d/%m/%Y %H:%i'
        )

        WHEN R.RegistrationDatetime
             REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
        THEN STR_TO_DATE(
            R.RegistrationDatetime,
            '%d/%m/%Y'
        )

        ELSE NULL
    END AS RegistrationDatetime,

    R.TierID

FROM (
    SELECT
        UPPER(
            REGEXP_REPLACE(
                TRIM(MemberID),
                '[^A-Za-z0-9]',
                ''
            )
        ) AS MemberID,

        TRIM(
            REPLACE(
                REPLACE(FullName, '\r', ''),
                '\n',
                ''
            )
        ) AS FullName,

        TRIM(
            REPLACE(
                REPLACE(ContactNo, '\r', ''),
                '\n',
                ''
            )
        ) AS ContactNo,

        TRIM(
            REPLACE(
                REPLACE(Email, '\r', ''),
                '\n',
                ''
            )
        ) AS Email,

        TRIM(
            REPLACE(
                REPLACE(DateOfBirth, '\r', ''),
                '\n',
                ''
            )
        ) AS DateOfBirth,

        TRIM(
            REPLACE(
                REPLACE(Gender, '\r', ''),
                '\n',
                ''
            )
        ) AS Gender,

        TRIM(
            REPLACE(
                REPLACE(Occupation, '\r', ''),
                '\n',
                ''
            )
        ) AS Occupation,

        TRIM(
            REPLACE(
                REPLACE(RegistrationDatetime, '\r', ''),
                '\n',
                ''
            )
        ) AS RegistrationDatetime,

        CASE
            WHEN UPPER(
                REGEXP_REPLACE(
                    TRIM(TierID),
                    '[^A-Za-z0-9]',
                    ''
                )
            ) = 'T00001'
            THEN 'T0001'

            ELSE UPPER(
                REGEXP_REPLACE(
                    TRIM(TierID),
                    '[^A-Za-z0-9]',
                    ''
                )
            )
        END AS TierID

    FROM `ca22a0402(stg)`.StgMember
) AS R

INNER JOIN ca22a0402.MembershipTier MT
    ON R.TierID = MT.TierID

LEFT JOIN ca22a0402.Member ExistingMember
    ON R.MemberID = ExistingMember.MemberID

WHERE R.MemberID <> 'MEMBERID'
  AND R.MemberID <> ''
  AND ExistingMember.MemberID IS NULL;


-- =====================================================
-- 14. Insert Cleaned Loan Data
-- =====================================================

INSERT INTO ca22a0402.Loan (
    MemberID,
    StaffID,
    BookID,
    CopySeqNo,
    StartDatetime,
    DueDate,
    ReturnDatetime
)
SELECT
    C.MemberID,
    C.StaffID,
    C.BookID,
    C.CopySeqNo,
    C.StartDatetime,
    C.DueDate,
    C.ReturnDatetime
FROM (
    SELECT
        R.MemberID,
        R.StaffID,
        R.BookID,

        CASE
            WHEN R.CopySeqNo REGEXP '^[0-9]+$'
            THEN CAST(R.CopySeqNo AS UNSIGNED)
            ELSE NULL
        END AS CopySeqNo,

        CASE
            WHEN R.LoanDatetime
                 REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{1,2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.LoanDatetime,
                '%Y-%m-%d %H:%i:%s'
            )

            WHEN R.LoanDatetime
                 REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{1,2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.LoanDatetime,
                '%Y-%m-%d %H:%i'
            )

            WHEN R.LoanDatetime
                 REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.LoanDatetime,
                '%d/%m/%Y %H:%i:%s'
            )

            WHEN R.LoanDatetime
                 REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.LoanDatetime,
                '%d/%m/%Y %H:%i'
            )

            ELSE NULL
        END AS StartDatetime,

        CASE
            WHEN R.DueDate
                 REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(
                R.DueDate,
                '%Y-%m-%d'
            )

            WHEN R.DueDate
                 REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
            THEN STR_TO_DATE(
                R.DueDate,
                '%d/%m/%Y'
            )

            ELSE NULL
        END AS DueDate,

        CASE
            WHEN R.ReturnDatetime IS NULL
              OR R.ReturnDatetime = ''
            THEN NULL

            WHEN R.ReturnDatetime
                 REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{1,2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.ReturnDatetime,
                '%Y-%m-%d %H:%i:%s'
            )

            WHEN R.ReturnDatetime
                 REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{1,2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.ReturnDatetime,
                '%Y-%m-%d %H:%i'
            )

            WHEN R.ReturnDatetime
                 REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.ReturnDatetime,
                '%d/%m/%Y %H:%i:%s'
            )

            WHEN R.ReturnDatetime
                 REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4} [0-9]{1,2}:[0-9]{2}$'
            THEN STR_TO_DATE(
                R.ReturnDatetime,
                '%d/%m/%Y %H:%i'
            )

            ELSE NULL
        END AS ReturnDatetime

    FROM (
        SELECT
            UPPER(
                REGEXP_REPLACE(
                    TRIM(MemberID),
                    '[^A-Za-z0-9]',
                    ''
                )
            ) AS MemberID,

            UPPER(
                REGEXP_REPLACE(
                    TRIM(StaffID),
                    '[^A-Za-z0-9]',
                    ''
                )
            ) AS StaffID,

            UPPER(
                REGEXP_REPLACE(
                    TRIM(BookID),
                    '[^A-Za-z0-9]',
                    ''
                )
            ) AS BookID,

            TRIM(
                REPLACE(
                    REPLACE(CopySeqNo, '\r', ''),
                    '\n',
                    ''
                )
            ) AS CopySeqNo,

            TRIM(
                REPLACE(
                    REPLACE(LoanDatetime, '\r', ''),
                    '\n',
                    ''
                )
            ) AS LoanDatetime,

            TRIM(
                REPLACE(
                    REPLACE(DueDate, '\r', ''),
                    '\n',
                    ''
                )
            ) AS DueDate,

            TRIM(
                REPLACE(
                    REPLACE(ReturnDatetime, '\r', ''),
                    '\n',
                    ''
                )
            ) AS ReturnDatetime

        FROM `ca22a0402(stg)`.StgLoan
    ) AS R
) AS C

INNER JOIN ca22a0402.Member M
    ON C.MemberID = M.MemberID

INNER JOIN ca22a0402.Staff S
    ON C.StaffID = S.StaffID

INNER JOIN ca22a0402.BookCopy BC
    ON C.BookID = BC.BookID
   AND C.CopySeqNo = BC.CopySeqNo

WHERE C.MemberID <> 'MEMBERID'
  AND C.MemberID <> ''
  AND C.StaffID <> ''
  AND C.BookID <> ''
  AND C.CopySeqNo IS NOT NULL
  AND C.StartDatetime IS NOT NULL
  AND C.DueDate IS NOT NULL;

UPDATE ca22a0402.BookCopy
SET Status = 'On Loan'
WHERE BookID = 'B00489'
  AND CopySeqNo = 2;

-- =====================================================
-- 15. Verification Queries
-- =====================================================

SELECT 'MembershipTier' AS TableName,
       COUNT(*) AS RowCount
FROM ca22a0402.MembershipTier

UNION ALL

SELECT 'Staff',
       COUNT(*)
FROM ca22a0402.Staff

UNION ALL

SELECT 'Book',
       COUNT(*)
FROM ca22a0402.Book

UNION ALL

SELECT 'BookCopy',
       COUNT(*)
FROM ca22a0402.BookCopy

UNION ALL

SELECT 'Member',
       COUNT(*)
FROM ca22a0402.Member

UNION ALL

SELECT 'Loan',
       COUNT(*)
FROM ca22a0402.Loan;

-- Compare source staging count against final OLTP count
SELECT
    'MembershipTier' AS TableName,
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgMembershipTier) AS StagingRows,
    (SELECT COUNT(*)
     FROM ca22a0402.MembershipTier) AS OLTPRows,
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgMembershipTier)
    -
    (SELECT COUNT(*)
     FROM ca22a0402.MembershipTier) AS Difference

UNION ALL

SELECT
    'Staff',
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgStaff),
    (SELECT COUNT(*)
     FROM ca22a0402.Staff),
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgStaff)
    -
    (SELECT COUNT(*)
     FROM ca22a0402.Staff)

UNION ALL

SELECT
    'Book',
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgBook),
    (SELECT COUNT(*)
     FROM ca22a0402.Book),
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgBook)
    -
    (SELECT COUNT(*)
     FROM ca22a0402.Book)

UNION ALL

SELECT
    'BookCopy',
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgBookCopy),
    (SELECT COUNT(*)
     FROM ca22a0402.BookCopy),
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgBookCopy)
    -
    (SELECT COUNT(*)
     FROM ca22a0402.BookCopy)

UNION ALL

SELECT
    'Member',
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgMember),
    (SELECT COUNT(*)
     FROM ca22a0402.Member),
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgMember)
    -
    (SELECT COUNT(*)
     FROM ca22a0402.Member)

UNION ALL

SELECT
    'Loan',
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgLoan),
    (SELECT COUNT(*)
     FROM ca22a0402.Loan),
    (SELECT COUNT(*)
     FROM `ca22a0402(stg)`.StgLoan)
    -
    (SELECT COUNT(*)
     FROM ca22a0402.Loan);
     
     
     
-- Confirm all due dates follow the required 14-day rule
SELECT *
FROM ca22a0402.Loan
WHERE DueDate <> DATE_ADD(DATE(StartDatetime), INTERVAL 14 DAY);

-- Confirm no return date occurs before borrowing
SELECT *
FROM ca22a0402.Loan
WHERE ReturnDatetime IS NOT NULL
  AND ReturnDatetime < StartDatetime;

-- Confirm one active loan remains in OLTP
SELECT COUNT(*) AS ActiveLoanCount
FROM ca22a0402.Loan
WHERE ReturnDatetime IS NULL;

-- Confirm no broken foreign-key references remain
SELECT L.*
FROM ca22a0402.Loan L
LEFT JOIN ca22a0402.Member M
    ON L.MemberID = M.MemberID
LEFT JOIN ca22a0402.Staff S
    ON L.StaffID = S.StaffID
LEFT JOIN ca22a0402.BookCopy BC
    ON L.BookID = BC.BookID
   AND L.CopySeqNo = BC.CopySeqNo
WHERE M.MemberID IS NULL
   OR S.StaffID IS NULL
   OR BC.BookID IS NULL;
   
-- General rejected-record query
SELECT
    SL.MemberID,
    SL.StaffID,
    SL.BookID,
    SL.CopySeqNo,

    CASE
        WHEN M.MemberID IS NULL THEN 'Invalid'
        ELSE 'Valid'
    END AS MemberValidation,

    CASE
        WHEN S.StaffID IS NULL THEN 'Invalid'
        ELSE 'Valid' 
    END AS StaffValidation,

    CASE
        WHEN BC.BookID IS NULL THEN 'Invalid'
        ELSE 'Valid'
    END AS BookCopyValidation

FROM `ca22a0402(stg)`.StgLoan SL

LEFT JOIN ca22a0402.Member M
    ON UPPER(
        REGEXP_REPLACE(
            TRIM(SL.MemberID),
            '[^A-Za-z0-9]',
            ''
        )
    ) = M.MemberID

LEFT JOIN ca22a0402.Staff S
    ON UPPER(
        REGEXP_REPLACE(
            TRIM(SL.StaffID),
            '[^A-Za-z0-9]',
            ''
        )
    ) = S.StaffID

LEFT JOIN ca22a0402.BookCopy BC
    ON UPPER(
        REGEXP_REPLACE(
            TRIM(SL.BookID),
            '[^A-Za-z0-9]',
            ''
        )
    ) = BC.BookID
   AND CASE
           WHEN TRIM(SL.CopySeqNo) REGEXP '^[0-9]+$'
           THEN CAST(TRIM(SL.CopySeqNo) AS UNSIGNED)
           ELSE NULL
       END = BC.CopySeqNo

WHERE M.MemberID IS NULL
   OR S.StaffID IS NULL
   OR BC.BookID IS NULL;

-- Confirm corrected member exists, specific to ca2 dataset
SELECT *
FROM ca22a0402.Member
WHERE MemberID = 'M0197';


-- Confirm invalid staff does not exist, specific to ca2 dataset
SELECT *
FROM ca22a0402.Staff
WHERE StaffID = 'S0101';


-- =====================================================
-- End of Script
-- =====================================================


