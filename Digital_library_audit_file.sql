SET @daily_penalty_rate = 5.00;
SET @loan_period_days = 14;
SET @inactive_years = 3;


DROP TABLE IF EXISTS IssuedBooks;
DROP TABLE IF EXISTS Books;
DROP TABLE IF EXISTS Students;


CREATE TABLE Students (
    StudentID     INT            PRIMARY KEY AUTO_INCREMENT,
    FullName      VARCHAR(100)   NOT NULL,
    Email         VARCHAR(150)   UNIQUE NOT NULL,
    Phone         VARCHAR(20),
    EnrolledDate  DATE           NOT NULL,
    IsActive      BOOLEAN        DEFAULT TRUE
);


CREATE TABLE Books (
    BookID          INT          PRIMARY KEY AUTO_INCREMENT,
    Title           VARCHAR(200) NOT NULL,
    Author          VARCHAR(150) NOT NULL,
    Category        VARCHAR(50)  NOT NULL,
    TotalCopies     INT          NOT NULL DEFAULT 1,
    AvailableCopies INT          NOT NULL DEFAULT 1,
    PublishedYear   INT,
    ISBN            VARCHAR(20)  UNIQUE
);


CREATE TABLE IssuedBooks (
    IssueID       INT  PRIMARY KEY AUTO_INCREMENT,
    StudentID     INT  NOT NULL,
    BookID        INT  NOT NULL,
    IssueDate     DATE NOT NULL,
    DueDate       DATE GENERATED ALWAYS AS (DATE_ADD(IssueDate, INTERVAL 14 DAY)) STORED,
    ReturnDate    DATE DEFAULT NULL,
    CONSTRAINT fk_student FOREIGN KEY (StudentID) REFERENCES Students(StudentID) ON DELETE CASCADE,
    CONSTRAINT fk_book    FOREIGN KEY (BookID)    REFERENCES Books(BookID)       ON DELETE CASCADE
);


INSERT INTO Students (FullName, Email, Phone, EnrolledDate) VALUES
    ('Aarav Sharma',   'aarav.sharma@college.edu', '9876543210', '2023-06-01'),
    ('Priya Nair',     'priya.nair@college.edu',   '9123456780', '2022-01-15'),
    ('Rohan Mehta',    'rohan.mehta@college.edu',  '9988776655', '2021-07-20'),
    ('Sneha Kulkarni', 'sneha.k@college.edu',      '9871234567', '2020-03-10'),
    ('Arjun Pillai',   'arjun.p@college.edu',      '9345678901', '2019-11-05'),
    ('Divya Rao',      'divya.rao@college.edu',    '9012345678', '2019-08-22'),
    ('Karan Joshi',    'karan.j@college.edu',      '9654321870', '2024-01-30'),
    ('Meera Iyer',     'meera.i@college.edu',      '9765432109', '2023-09-12');


INSERT INTO Books (Title, Author, Category, TotalCopies, AvailableCopies, PublishedYear, ISBN) VALUES
    ('The Alchemist',                  'Paulo Coelho',      'Fiction',    3, 2, 1988, '978-0062315007'),
    ('Sapiens',                        'Yuval Noah Harari', 'History',    4, 3, 2011, '978-0062316097'),
    ('A Brief History of Time',        'Stephen Hawking',   'Science',    2, 1, 1988, '978-0553380163'),
    ('Harry Potter & Sorcerers Stone', 'J.K. Rowling',      'Fiction',    5, 3, 1997, '978-0590353427'),
    ('The Origin of Species',          'Charles Darwin',    'Science',    2, 2, 1859, '978-0140432053'),
    ('Thinking, Fast and Slow',        'Daniel Kahneman',   'Psychology', 3, 2, 2011, '978-0374533557'),
    ('Cosmos',                         'Carl Sagan',        'Science',    2, 1, 1980, '978-0345331359'),
    ('To Kill a Mockingbird',          'Harper Lee',        'Fiction',    3, 2, 1960, '978-0061935466'),
    ('The Diary of a Young Girl',      'Anne Frank',        'History',    2, 1, 1947, '978-0553577129'),
    ('Guns, Germs, and Steel',         'Jared Diamond',     'History',    2, 2, 1997, '978-0393317558');


INSERT INTO IssuedBooks (StudentID, BookID, IssueDate, ReturnDate) VALUES
    (1, 1,  DATE_SUB(CURRENT_DATE, INTERVAL 20 DAY),   NULL),
    (2, 3,  DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY),   NULL),
    (3, 6,  DATE_SUB(CURRENT_DATE, INTERVAL 25 DAY),   NULL),
    (7, 7,  DATE_SUB(CURRENT_DATE, INTERVAL 18 DAY),   NULL),
    (4, 2,  DATE_SUB(CURRENT_DATE, INTERVAL 10 DAY),   DATE_SUB(CURRENT_DATE, INTERVAL 4 DAY)),
    (5, 4,  DATE_SUB(CURRENT_DATE, INTERVAL 12 DAY),   DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY)),
    (1, 5,  DATE_SUB(CURRENT_DATE, INTERVAL 40 DAY),   DATE_SUB(CURRENT_DATE, INTERVAL 15 DAY)),
    (8, 8,  DATE_SUB(CURRENT_DATE, INTERVAL 35 DAY),   DATE_SUB(CURRENT_DATE, INTERVAL 10 DAY)),
    (2, 9,  DATE_SUB(CURRENT_DATE, INTERVAL 5 DAY),    NULL),
    (8, 4,  DATE_SUB(CURRENT_DATE, INTERVAL 3 DAY),    NULL),
    (7, 2,  DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY),    NULL),
    (5, 10, DATE_SUB(CURRENT_DATE, INTERVAL 1200 DAY), DATE_SUB(CURRENT_DATE, INTERVAL 1195 DAY)),
    (6, 1,  DATE_SUB(CURRENT_DATE, INTERVAL 1100 DAY), DATE_SUB(CURRENT_DATE, INTERVAL 1090 DAY));


SELECT
    s.StudentID,
    s.FullName                                             AS StudentName,
    s.Email,
    b.Title                                                AS BookTitle,
    b.Category,
    ib.IssueDate,
    ib.DueDate,
    DATEDIFF(CURRENT_DATE, ib.DueDate)                     AS DaysOverdue,
    ROUND(
        DATEDIFF(CURRENT_DATE, ib.DueDate) * @daily_penalty_rate, 2
    )                                                      AS PenaltyDue
FROM IssuedBooks ib
JOIN Students s ON ib.StudentID = s.StudentID
JOIN Books    b ON ib.BookID    = b.BookID
WHERE ib.ReturnDate IS NULL
  AND ib.IssueDate < DATE_SUB(CURRENT_DATE, INTERVAL @loan_period_days DAY)
ORDER BY DaysOverdue DESC;


SELECT
    b.Category,
    COUNT(ib.IssueID)                                      AS TotalBorrows,
    COUNT(CASE WHEN ib.ReturnDate IS NULL THEN 1 END)      AS CurrentlyBorrowed,
    COUNT(CASE WHEN ib.ReturnDate IS NOT NULL THEN 1 END)  AS Returned,
    ROUND(
        COUNT(ib.IssueID) * 100.0 /
        SUM(COUNT(ib.IssueID)) OVER (), 1
    )                                                      AS SharePercent
FROM Books b
LEFT JOIN IssuedBooks ib ON b.BookID = ib.BookID
GROUP BY b.Category
ORDER BY TotalBorrows DESC;


SELECT
    b.BookID,
    b.Title,
    b.Author,
    b.Category,
    COUNT(ib.IssueID)  AS TimesBorrowed,
    b.AvailableCopies
FROM Books b
LEFT JOIN IssuedBooks ib ON b.BookID = ib.BookID
GROUP BY b.BookID, b.Title, b.Author, b.Category, b.AvailableCopies
ORDER BY TimesBorrowed DESC
LIMIT 10;


SELECT
    s.StudentID,
    s.FullName,
    s.Email,
    s.EnrolledDate,
    MAX(ib.IssueDate)                         AS LastBorrowDate,
    DATEDIFF(CURRENT_DATE, MAX(ib.IssueDate)) AS DaysSinceLastBorrow
FROM Students s
LEFT JOIN IssuedBooks ib ON s.StudentID = ib.StudentID
GROUP BY s.StudentID, s.FullName, s.Email, s.EnrolledDate
HAVING LastBorrowDate IS NULL
    OR MAX(ib.IssueDate) < DATE_SUB(CURRENT_DATE, INTERVAL @inactive_years YEAR)
ORDER BY LastBorrowDate ASC;


UPDATE Students s
LEFT JOIN (
    SELECT StudentID, MAX(IssueDate) AS LastBorrow
    FROM IssuedBooks
    GROUP BY StudentID
) last_activity ON s.StudentID = last_activity.StudentID
SET s.IsActive = FALSE
WHERE last_activity.LastBorrow IS NULL
   OR last_activity.LastBorrow < DATE_SUB(CURRENT_DATE, INTERVAL @inactive_years YEAR);


SELECT
    s.StudentID,
    s.FullName,
    s.Email,
    COUNT(ib.IssueID)                                             AS TotalBorrows,
    SUM(CASE WHEN ib.ReturnDate IS NULL AND
                  ib.IssueDate < DATE_SUB(CURRENT_DATE, INTERVAL @loan_period_days DAY)
             THEN 1 ELSE 0 END)                                   AS OverdueBooks,
    ROUND(
        SUM(
            CASE
                WHEN ib.ReturnDate IS NOT NULL
                     AND ib.ReturnDate > DATE_ADD(ib.IssueDate, INTERVAL @loan_period_days DAY)
                     THEN DATEDIFF(ib.ReturnDate, DATE_ADD(ib.IssueDate, INTERVAL @loan_period_days DAY)) * @daily_penalty_rate
                WHEN ib.ReturnDate IS NULL
                     AND CURRENT_DATE > DATE_ADD(ib.IssueDate, INTERVAL @loan_period_days DAY)
                     THEN DATEDIFF(CURRENT_DATE, DATE_ADD(ib.IssueDate, INTERVAL @loan_period_days DAY)) * @daily_penalty_rate
                ELSE 0
            END
        ), 2
    )                                                             AS TotalPenalty
FROM Students s
JOIN IssuedBooks ib ON s.StudentID = ib.StudentID
GROUP BY s.StudentID, s.FullName, s.Email
HAVING TotalPenalty > 0
ORDER BY TotalPenalty DESC;
