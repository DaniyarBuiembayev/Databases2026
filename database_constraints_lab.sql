-- ============================================================
-- Database Constraints - Laboratory Work
-- Name: Daniyar Buiembayev
-- Student ID: 25B031184
-- ============================================================
-- PART 1: CHECK CONSTRAINTS
-- ============================================================

DROP TABLE IF EXISTS order_details, orders, products, customers CASCADE;
DROP TABLE IF EXISTS order_items, products_fk, categories CASCADE;
DROP TABLE IF EXISTS books, authors, publishers CASCADE;
DROP TABLE IF EXISTS employees_dept, departments CASCADE;
DROP TABLE IF EXISTS student_courses, course_enrollments, users CASCADE;
DROP TABLE IF EXISTS inventory, customers CASCADE;
DROP TABLE IF EXISTS bookings, products_catalog, employees CASCADE;

-- Task 1.1: 
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CONSTRAINT chk_employee_age CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CONSTRAINT chk_employee_salary CHECK (salary > 0)
);

INSERT INTO employees VALUES
(1, 'Ayan', 'Sadykov', 25, 350000),
(2, 'Dana', 'Kim', 41, 520000);

-- Expected CHECK violations:
-- INSERT INTO employees VALUES (3, 'Tim', 'Lee', 17, 200000);
-- ERROR: chk_employee_age (age must be between 18 and 65).
-- INSERT INTO employees VALUES (4, 'Mira', 'Ali', 30, 0);
-- ERROR: chk_employee_salary (salary must be greater than 0).

-- Task 1.2: 
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

INSERT INTO products_catalog VALUES
(1, 'Keyboard', 20000, 16000),
(2, 'Mouse', 10000, 7500);

-- Expected valid_discount violations:
-- INSERT INTO products_catalog VALUES (3, 'Monitor', 0, 100);
-- ERROR: regular_price must be greater than 0.
-- INSERT INTO products_catalog VALUES (4, 'Cable', 1000, 0);
-- ERROR: discount_price must be greater than 0.
-- INSERT INTO products_catalog VALUES (5, 'Headphones', 10000, 12000);
-- ERROR: discount_price must be less than regular_price.

-- Task 1.3:
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER,
    CONSTRAINT chk_booking_guests CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT chk_booking_dates CHECK (check_out_date > check_in_date)
);

INSERT INTO bookings VALUES
(1, DATE '2026-11-01', DATE '2026-11-05', 2),
(2, DATE '2026-12-10', DATE '2026-12-12', 6);

-- Expected CHECK violations:
-- INSERT INTO bookings VALUES (3, DATE '2026-11-01', DATE '2026-11-02', 0);
-- ERROR: chk_booking_guests (num_guests must be 1..10).
-- INSERT INTO bookings VALUES (4, DATE '2026-11-05', DATE '2026-11-05', 2);
-- ERROR: chk_booking_dates (check-out must be after check-in).
-- INSERT INTO bookings VALUES (5, DATE '2026-11-05', DATE '2026-11-04', 2);
-- ERROR: chk_booking_dates (check-out is earlier than check-in).

-- ============================================================
-- PART 2: NOT NULL CONSTRAINTS
-- ============================================================

-- Task 2.1: 
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT, -- Nullable by design
    registration_date DATE NOT NULL
);

INSERT INTO customers VALUES
(1, 'aida@example.com', '+77010000001', DATE '2026-01-10'),
(2, 'nurlan@example.com', NULL, DATE '2026-02-15');

-- Expected NOT NULL violations:
-- INSERT INTO customers VALUES (3, NULL, '+77010000003', DATE '2026-03-01');
-- ERROR: email cannot be NULL.
-- INSERT INTO customers VALUES (NULL, 'test@example.com', NULL, DATE '2026-03-01');
-- ERROR: customer_id cannot be NULL.
-- INSERT INTO customers VALUES (4, 'test2@example.com', NULL, NULL);
-- ERROR: registration_date cannot be NULL.
-- The second valid row demonstrates that phone may be NULL.

-- Task 2.2: 
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory VALUES
(1, 'USB-C Cable', 40, 2500, TIMESTAMP '2026-10-01 09:00:00'),
(2, 'Laptop Stand', 12, 8500, CURRENT_TIMESTAMP);

-- Expected errors:
-- INSERT INTO inventory VALUES (3, NULL, 2, 1000, CURRENT_TIMESTAMP);
-- ERROR: item_name cannot be NULL.
-- INSERT INTO inventory VALUES (4, 'SSD', NULL, 25000, CURRENT_TIMESTAMP);
-- ERROR: quantity cannot be NULL.
-- INSERT INTO inventory VALUES (5, 'SSD', -1, 25000, CURRENT_TIMESTAMP);
-- ERROR: quantity must be >= 0.
-- INSERT INTO inventory VALUES (6, 'SSD', 3, 0, CURRENT_TIMESTAMP);
-- ERROR: unit_price must be > 0.
-- INSERT INTO inventory VALUES (7, 'SSD', 3, 25000, NULL);
-- ERROR: last_updated cannot be NULL.

-- ============================================================
-- PART 3: UNIQUE CONSTRAINTS
-- ============================================================

-- Task 3.1 and 3.3: 
CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

INSERT INTO users VALUES
(1, 'daniyar01', 'daniyar01@example.com', CURRENT_TIMESTAMP),
(2, 'aigerim_k', 'aigerim@example.com', CURRENT_TIMESTAMP),
(3, 'arman_dev', 'arman@example.com', CURRENT_TIMESTAMP);

-- Expected UNIQUE violations:
-- INSERT INTO users VALUES (4, 'daniyar01', 'new@example.com', CURRENT_TIMESTAMP);
-- ERROR: unique_username (username already exists).
-- INSERT INTO users VALUES (5, 'new_user', 'aigerim@example.com', CURRENT_TIMESTAMP);
-- ERROR: unique_email (email already exists).
-- Note: UNIQUE permits multiple NULL values in PostgreSQL by default.
-- Add NOT NULL too if the column must always contain a value.

-- Task 3.2: a student cannot enroll in the same course in the same semester twice.
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_student_course_semester
        UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES
(1, 1001, 'CS101', 'Fall 2026'),
(2, 1001, 'DB201', 'Fall 2026'),
(3, 1001, 'CS101', 'Spring 2027');

-- Expected composite UNIQUE violation:
-- INSERT INTO course_enrollments VALUES (4, 1001, 'CS101', 'Fall 2026');
-- ERROR: unique_student_course_semester (same student, course and semester).

-- ============================================================
-- PART 4: PRIMARY KEY CONSTRAINTS
-- ============================================================

-- Task 4.1: 
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES
(10, 'Information Technology', 'Almaty'),
(20, 'Finance', 'Astana'),
(30, 'Human Resources', 'Shymkent');

-- Expected primary key violations:
-- INSERT INTO departments VALUES (10, 'Marketing', 'Almaty');
-- ERROR: duplicate dept_id violates departments_pkey.
-- INSERT INTO departments VALUES (NULL, 'Legal', 'Almaty');
-- ERROR: dept_id (PRIMARY KEY) cannot be NULL.

-- Task 4.2: 
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    CONSTRAINT student_courses_pkey PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES
(1001, 201, DATE '2026-09-01', 'A'),
(1001, 202, DATE '2026-09-02', 'B'),
(1002, 201, DATE '2026-09-01', 'A');

-- Expected composite PRIMARY KEY violation:
-- INSERT INTO student_courses VALUES (1001, 201, DATE '2026-09-10', 'C');
-- ERROR: the pair (student_id, course_id) already exists.

-- Task 4.3: Comparison notes
-- UNIQUE фтв PRIMARY KEY:
-- 1. PRIMARY KEY uniquely identifies each row and disallows NULL values.
-- 2. A table has exactly one PRIMARY KEY constraint; it may contain multiple columns.
-- 3. A table can have multiple UNIQUE constraints for alternate candidate identifiers.
-- 4. UNIQUE allows NULL values by default in PostgreSQL (multiple NULLs by default).
-- Single-column PK: use when one attribute, such as customer_id, identifies a row.
-- Composite PK: use when the combination identifies a row, e.g. student_id + course_id.
-- A table has one PRIMARY KEY because it defines the table's chosen row identity;
-- additional unique business rules are represented with UNIQUE constraints.

-- ============================================================
-- PART 5: FOREIGN KEY CONSTRAINTS
-- ============================================================

-- Task 5.1: 
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES
(101, 'Maksat', 10, DATE '2025-06-01'),
(102, 'Madina', 20, DATE '2025-08-15'),
(103, 'Samat', 30, DATE '2026-01-10');

-- Expected FOREIGN KEY violation:
-- INSERT INTO employees_dept VALUES (104, 'Dana', 999, DATE '2026-03-01');
-- ERROR: dept_id 999 does not exist in departments.

-- Task 5.2: 
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES
(1, 'Abai Qunanbaiuly', 'Kazakhstan'),
(2, 'Mukhtar Auezov', 'Kazakhstan'),
(3, 'George Orwell', 'United Kingdom'),
(4, 'Jane Austen', 'United Kingdom'),
(5, 'Chingiz Aitmatov', 'Kyrgyzstan');

INSERT INTO publishers VALUES
(1, 'Qazaq Press', 'Almaty'),
(2, 'Classic House', 'Astana'),
(3, 'Penguin Books', 'London'),
(4, 'Oxford Press', 'Oxford'),
(5, 'Nomad Publishing', 'Bishkek');

INSERT INTO books VALUES
(1, 'Words of Edification', 1, 1, 1890, '9780000000001'),
(2, 'The Path of Abai', 2, 2, 1942, '9780000000002'),
(3, 'Animal Farm', 3, 3, 1945, '9780000000003'),
(4, 'Pride and Prejudice', 4, 4, 1813, '9780000000004'),
(5, 'Jamila', 5, 5, 1958, '9780000000005');

-- Expected FOREIGN KEY violation:
-- INSERT INTO books VALUES (6, 'Unknown Book', 999, 1, 2026, '9780000000006');
-- ERROR: author_id 999 does not exist in authors.
-- Expected UNIQUE violation:
-- INSERT INTO books VALUES (7, 'Duplicate ISBN', 1, 1, 2026, '9780000000001');
-- ERROR: ISBN must be unique.

-- Task 5.3: 
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES
(1, 'Electronics'),
(2, 'Stationery');

INSERT INTO products_fk VALUES
(1, 'Keyboard', 1),
(2, 'Notebook', 2);

INSERT INTO orders VALUES
(1, DATE '2026-10-01'),
(2, DATE '2026-10-02');

INSERT INTO order_items VALUES
(1, 1, 1, 2),
(2, 1, 2, 1),
(3, 2, 2, 5);

-- Test 1: RESTRICT prevents deleting a category referenced by a product.
-- DELETE FROM categories WHERE category_id = 1;
-- Expected: ERROR; products_fk references category 1, so deletion is restricted.
-- Test 2: CASCADE deletes order_items belonging to order 1 automatically.
-- DELETE FROM orders WHERE order_id = 1;
-- Expected: order 1 is deleted and its order_items (item_id 1 and 2) are deleted.
-- Run these verification queries before/after uncommenting the DELETE:
SELECT * FROM categories ORDER BY category_id;
SELECT * FROM order_items ORDER BY item_id;
-- ON DELETE RESTRICT protects referenced parent rows.
-- ON DELETE CASCADE automatically removes dependent child rows.

-- ============================================================
-- PART 6: PRACTICAL APPLICATION - E-COMMERCE DATABASE
-- ============================================================

ALTER TABLE customers RENAME TO customers_not_null_practice;
ALTER TABLE orders RENAME TO orders_fk_practice;


CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);


CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    order_date DATE NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    status TEXT NOT NULL CHECK (
        status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')
    )
);


CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0)
);


INSERT INTO customers VALUES
(1, 'Daniyar Sadykov', 'daniyar.shop@example.com', '+77010000001', DATE '2026-01-05'),
(2, 'Aigerim Omarova', 'aigerim.shop@example.com', '+77010000002', DATE '2026-02-10'),
(3, 'Arman Bekov', 'arman.shop@example.com', NULL, DATE '2026-03-15'),
(4, 'Madina Aliyeva', 'madina.shop@example.com', '+77010000004', DATE '2026-04-20'),
(5, 'Nurlan Kim', 'nurlan.shop@example.com', '+77010000005', DATE '2026-05-25');


INSERT INTO products VALUES
(1, 'Wireless Mouse', 'Wireless optical mouse', 7500.00, 40),
(2, 'Keyboard', 'Mechanical keyboard', 22000.00, 15),
(3, 'Monitor', '24-inch monitor', 68000.00, 8),
(4, 'USB-C Cable', '1 metre cable', 2500.00, 100),
(5, 'Laptop Stand', 'Aluminium stand', 12000.00, 20);


INSERT INTO orders VALUES
(1, 1, DATE '2026-09-01', 15000.00, 'pending'),
(2, 2, DATE '2026-09-02', 22000.00, 'processing'),
(3, 3, DATE '2026-09-03', 68000.00, 'shipped'),
(4, 4, DATE '2026-09-04', 5000.00, 'delivered'),
(5, 5, DATE '2026-09-05', 24000.00, 'cancelled');


INSERT INTO order_details VALUES
(1, 1, 1, 2, 7500.00),
(2, 2, 2, 1, 22000.00),
(3, 3, 3, 1, 68000.00),
(4, 4, 4, 2, 2500.00),
(5, 5, 5, 2, 12000.00),
(6, 1, 4, 1, 2500.00);



SELECT * FROM customers ORDER BY customer_id;
SELECT * FROM products ORDER BY product_id;
SELECT * FROM orders ORDER BY order_id;
SELECT * FROM order_details ORDER BY order_detail_id;


SELECT
    o.order_id,
    c.name AS customer_name,
    o.status,
    p.name AS product_name,
    od.quantity,
    od.unit_price,
    od.quantity * od.unit_price AS line_total
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
JOIN order_details AS od ON od.order_id = o.order_id
JOIN products AS p ON p.product_id = od.product_id
ORDER BY o.order_id, od.order_detail_id;


-- ============================================================
-- END OF LABORATORY WORK
-- ============================================================
