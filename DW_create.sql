DROP DATABASE IF EXISTS CA2DW2A0402;
CREATE DATABASE CA2DW2A0402;
USE CA2DW2A0402;

CREATE TABLE DimMember (
    MemberKey INT AUTO_INCREMENT PRIMARY KEY,
    MemberID CHAR(10) NOT NULL UNIQUE,
    Gender CHAR(1) NOT NULL,
    Occupation VARCHAR(100),
    MembershipTier VARCHAR(20) NOT NULL,
    AgeGroup VARCHAR(20) NOT NULL,
    RegistrationDate DATE NOT NULL
);

CREATE TABLE DimBook (
    BookKey INT AUTO_INCREMENT PRIMARY KEY,
    BookID CHAR(10) NOT NULL UNIQUE,
    Title VARCHAR(200) NOT NULL,
    Genre VARCHAR(100) NOT NULL,
    Author VARCHAR(100) NOT NULL,
    MinimumMembershipTier VARCHAR(20) NOT NULL
);

CREATE TABLE DimStaff (
    StaffKey INT AUTO_INCREMENT PRIMARY KEY,
    StaffID CHAR(10) NOT NULL UNIQUE,
    Gender CHAR(1) NOT NULL,
    EmploymentType VARCHAR(20) NOT NULL,
    Department VARCHAR(100) NOT NULL,
    StartDate DATE NOT NULL
);

CREATE TABLE DimDate (
    DateKey INT AUTO_INCREMENT PRIMARY KEY,
    FullDate DATE NOT NULL UNIQUE,
    DayOfMonth TINYINT NOT NULL,
    DayOfWeekNumber TINYINT NOT NULL,
    DayOfWeekName VARCHAR(10) NOT NULL,
    MonthNumber TINYINT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    Quarter TINYINT NOT NULL,
    Year SMALLINT NOT NULL,
    IsWeekend BOOLEAN NOT NULL
);

CREATE TABLE FactLoan (
    FactLoanKey INT AUTO_INCREMENT PRIMARY KEY,
    MemberKey INT NOT NULL,
    BookKey INT NOT NULL,
    StaffKey INT NOT NULL,
    BorrowDateKey INT NOT NULL,
    LoanDuration INT NOT NULL,
    WasLate BOOLEAN NOT NULL,

    CONSTRAINT FK_FactLoan_Member
        FOREIGN KEY (MemberKey)
        REFERENCES DimMember(MemberKey),

    CONSTRAINT FK_FactLoan_Book
        FOREIGN KEY (BookKey)
        REFERENCES DimBook(BookKey),

    CONSTRAINT FK_FactLoan_Staff
        FOREIGN KEY (StaffKey)
        REFERENCES DimStaff(StaffKey),

    CONSTRAINT FK_FactLoan_BorrowDate
        FOREIGN KEY (BorrowDateKey)
        REFERENCES DimDate(DateKey)
);