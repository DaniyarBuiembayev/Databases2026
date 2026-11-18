-- Laboratory Work 8: SQL Indexes

-- SQL snippet 1
-- Create tables
CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(100),
 dept_id INT,
 salary DECIMAL(10,2),
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
 proj_id INT PRIMARY KEY,
 proj_name VARCHAR(100),
 budget DECIMAL(12,2),
 dept_id INT,
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
-- Insert sample data
INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');
INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);
INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

-- SQL snippet 2
CREATE INDEX emp_salary_idx ON employees(salary);
Verify the index was created:
sql

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

-- SQL snippet 3
CREATE INDEX emp_dept_idx ON employees(dept_id);
Test the index usage:
sql

SELECT * FROM employees WHERE dept_id = 101;

-- SQL snippet 4

SELECT
 tablename,
 indexname,
 indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- SQL snippet 5
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);
Test the multicolumn index:
sql

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- SQL snippet 6
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
Compare with queries:
sql
-- Query 1: Filters by dept_id first
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- Query 2: Filters by salary first
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;

-- SQL snippet 7
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;
Now create a unique index on the email column:
sql
CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);
Test the uniqueness constraint:
sql

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- SQL snippet 8

ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;
View the indexes:
sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- SQL snippet 9
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);
Test with an ORDER BY query:
sql
SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- SQL snippet 10
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);
Test the index:
sql
SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

-- SQL snippet 11
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));
Test the expression index:
sql

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

-- SQL snippet 12
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));
Test the index:
sql
SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- SQL snippet 13
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;
Verify the rename:
sql
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- SQL snippet 14
DROP INDEX emp_salary_dept_idx;

-- SQL snippet 15
REINDEX INDEX employees_salary_index;

-- SQL snippet 16
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;
Create indexes to optimize this query:
sql
-- Index for the WHERE clause
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;


-- SQL snippet 17
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;
Test the partial index:
sql
SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- SQL snippet 18
EXPLAIN SELECT * FROM employees WHERE salary > 52000;

-- SQL snippet 19
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
Test the hash index:
sql
SELECT * FROM departments WHERE dept_name = 'IT';

-- SQL snippet 20

CREATE INDEX proj_name_btree_idx ON projects(proj_name);

CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);
Test with different queries:
sql
-- Equality search (both can be used)
SELECT * FROM projects WHERE proj_name = 'Website Redesign';
-- Range search (only B-tree can be used)
SELECT * FROM projects WHERE proj_name > 'Database';

-- SQL snippet 21
SELECT
 schemaname,
 tablename,
 indexname,
 pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- SQL snippet 22

DROP INDEX IF EXISTS proj_name_hash_idx;


-- SQL snippet 23
CREATE VIEW index_documentation AS
SELECT
 tablename,
 indexname,
 indexdef,
 'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
 AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;
