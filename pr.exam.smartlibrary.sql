CREATE DATABASE SmartLibrary;
USE SmartLibrary;

-- 1. CREATE TABLES

CREATE TABLE Authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(150),
    author_id INT,
    category VARCHAR(50),
    isbn VARCHAR(20),
    published_date DATE,
    price DECIMAL(10,2),
    available_copies INT,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id)
);

CREATE TABLE Members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100),
    phone_number VARCHAR(15),
    membership_date DATE
);

CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT,
    book_id INT,
    borrow_date DATE,
    return_date DATE,
    fine_amount DECIMAL(10,2),
    FOREIGN KEY (member_id) REFERENCES Members(member_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

-- 2. INSERT SAMPLE DATA

INSERT INTO Authors (name, email) VALUES
('R.K. Narayan','rk@email.com'),
('Chetan Bhagat','chetan@email.com'),
('APJ Abdul Kalam','kalam@email.com');

INSERT INTO Books (title, author_id, category, isbn, published_date, price, available_copies) VALUES
('Malgudi Days',1,'Fiction','1111','2010-05-10',450,5),
('Five Point Someone',2,'Education','2222','2015-08-12',550,3),
('Wings of Fire',3,'Science','3333','2020-01-01',300,4),
('Ignited Minds',3,'Science','4444','2018-03-15',480,2);

INSERT INTO Members (name,email,phone_number,membership_date) VALUES
('Yash Patel','yash@email.com','9999999999','2023-01-10'),
('Rahul Shah','rahul@email.com','8888888888','2021-06-20'),
('Priya Mehta',NULL,'7777777777','2024-02-01');

INSERT INTO Transactions (member_id,book_id,borrow_date,return_date,fine_amount) VALUES
(1,3,'2024-01-01','2024-01-10',0),
(2,1,'2023-05-05','2023-05-20',50),
(1,4,'2024-02-01',NULL,0);

-- TASK 1: CRUD OPERATIONS

-- Insert
INSERT INTO Books (title, author_id, category, isbn, published_date, price, available_copies)
VALUES ('New Book',1,'Fiction','5555','2022-01-01',600,6);

-- Update availability when borrowed
UPDATE Books
SET available_copies = available_copies - 1
WHERE book_id = 3;

-- Delete inactive members (no borrow in last 1 year)
DELETE FROM Members
WHERE member_id NOT IN (
    SELECT DISTINCT member_id FROM Transactions
    WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
);

-- Retrieve available books
SELECT * FROM Books WHERE available_copies > 0;

-- TASK 2: WHERE, HAVING, LIMIT

SELECT * FROM Books WHERE YEAR(published_date) > 2015;

SELECT * FROM Books ORDER BY price DESC LIMIT 5;

SELECT * FROM Members WHERE YEAR(membership_date) < 2022;

-- TASK 3: AND, OR, NOT

SELECT * FROM Books 
WHERE category = 'Science' AND price < 500;

SELECT * FROM Books 
WHERE available_copies = 0;

SELECT * FROM Members 
WHERE YEAR(membership_date) > 2020 
OR member_id IN (
    SELECT member_id FROM Transactions
    GROUP BY member_id
    HAVING COUNT(book_id) > 3
);


-- TASK 4: ORDER BY, GROUP BY

SELECT * FROM Books ORDER BY title ASC;

SELECT member_id, COUNT(book_id) AS total_books
FROM Transactions
GROUP BY member_id;

SELECT category, COUNT(*) AS total_books
FROM Books
GROUP BY category;

-- TASK 5: AGGREGATE FUNCTIONS

SELECT category, COUNT(*) FROM Books GROUP BY category;

SELECT AVG(price) FROM Books;

SELECT book_id, COUNT(*) AS borrow_count
FROM Transactions
GROUP BY book_id
ORDER BY borrow_count DESC
LIMIT 1;

SELECT SUM(fine_amount) FROM Transactions;


-- TASK 6: PRIMARY & FOREIGN KEY
-- Already established during table creation


-- TASK 7: JOINS

-- INNER JOIN
SELECT b.title, a.name
FROM Books b
INNER JOIN Authors a ON b.author_id = a.author_id;

-- LEFT JOIN
SELECT m.name, t.book_id
FROM Members m
LEFT JOIN Transactions t ON m.member_id = t.member_id;

-- RIGHT JOIN
SELECT b.title, t.transaction_id
FROM Books b
RIGHT JOIN Transactions t ON b.book_id = t.book_id;

-- FULL OUTER JOIN (MySQL alternative using UNION)
SELECT m.name, t.book_id
FROM Members m
LEFT JOIN Transactions t ON m.member_id = t.member_id
UNION
SELECT m.name, t.book_id
FROM Members m
RIGHT JOIN Transactions t ON m.member_id = t.member_id;

-- TASK 8: SUBQUERIES

SELECT * FROM Books
WHERE book_id IN (
    SELECT book_id FROM Transactions
    WHERE member_id IN (
        SELECT member_id FROM Members
        WHERE YEAR(membership_date) > 2022
    )
);

SELECT * FROM Books
WHERE book_id = (
    SELECT book_id FROM Transactions
    GROUP BY book_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

SELECT * FROM Members
WHERE member_id NOT IN (
    SELECT DISTINCT member_id FROM Transactions
);

-- TASK 9: DATE FUNCTIONS

SELECT YEAR(published_date), COUNT(*)
FROM Books
GROUP BY YEAR(published_date);

SELECT DATEDIFF(return_date, borrow_date) AS days_difference
FROM Transactions;

SELECT DATE_FORMAT(borrow_date,'%d-%m-%Y')
FROM Transactions;

-- TASK 10: STRING FUNCTIONS

SELECT UPPER(title) FROM Books;

SELECT TRIM(name) FROM Authors;

SELECT IFNULL(email,'Not Provided') FROM Members;

-- TASK 11: WINDOW FUNCTIONS

SELECT 
    book_id, 
    COUNT(transaction_id) AS borrow_count,
    RANK() OVER (ORDER BY COUNT(transaction_id) DESC) AS borrow_rank
FROM Transactions
GROUP BY book_id;

SELECT 
    member_id, 
    borrow_date,
    COUNT(*) OVER (PARTITION BY member_id ORDER BY borrow_date) AS cumulative_borrows
FROM Transactions;


SELECT 
    MONTH(borrow_date) AS month,
    COUNT(transaction_id) AS monthly_count,
    AVG(COUNT(transaction_id)) OVER (ORDER BY MONTH(borrow_date) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM Transactions;

#task 12 - SQLCASE EXPRESSION

SELECT m.name,
    CASE 
        WHEN MAX(t.borrow_date) >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) THEN 'Active'
        ELSE 'Inactive'
    END AS Membership_Status
FROM Members m
LEFT JOIN Transactions t ON m.member_id = t.member_id
GROUP BY m.member_id, m.name;

-- 2. Categorize books based on publication year
SELECT 
    title,
    published_date,
    CASE 
        WHEN YEAR(published_date) > 2020 THEN 'New Arrival'
        WHEN YEAR(published_date) < 2000 THEN 'Classic'
        ELSE 'Regular'
    END AS Book_Category
FROM Books;