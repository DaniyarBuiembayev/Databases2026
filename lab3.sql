CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

INSERT INTO employees
    (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('John', 'Smith', 'IT', 90000, '2019-05-10', 'Active'),
    ('Alice', 'Brown', 'IT', 65000, '2021-03-15', 'Active'),
    ('Michael', 'Johnson', 'Sales', 55000, '2018-07-20', 'Active'),
    ('Sarah', 'Davis', 'Sales', 75000, '2022-01-10', 'Active'),
    ('David', 'Wilson', 'HR', 45000, '2023-05-01', 'Active'),
    ('Emma', 'Taylor', 'HR', 35000, '2024-02-15', 'Inactive'),
    ('Robert', 'Anderson', 'IT', 85000, '2019-11-12', 'Terminated'),
    ('Daniel', 'Thomas', 'Sales', 48000, '2024-06-01', 'Active');

INSERT INTO departments
    (dept_name, budget, manager_id)
VALUES
    ('IT', 120000, 1),
    ('Sales', 90000, 3),
    ('HR', 70000, 5),
    ('Management', 150000, NULL),
    ('Senior', 100000, NULL),
    ('Junior', 60000, NULL);

INSERT INTO projects
    (project_name, dept_id, start_date, end_date, budget)
VALUES
    ('Legacy System', 1, '2021-01-01', '2022-12-31', 40000),
    ('New Website', 2, '2024-01-01', '2024-12-31', 75000),
    ('HR Automation', 3, '2023-02-01', '2024-06-30', 55000),
    ('Management Platform', 4, '2024-01-01', '2025-12-31', 100000),
    ('Senior Analytics', 5, '2024-03-01', '2025-12-31', 80000),
    ('Junior Training', 6, '2024-05-01', '2025-11-30', 60000);

INSERT INTO employees
    (emp_id, first_name, last_name, department)
VALUES
    (100, 'James', 'Miller', 'IT');

INSERT INTO employees
    (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('Olivia', 'Moore', 'HR', DEFAULT, '2025-01-15', DEFAULT);

INSERT INTO departments
    (dept_name, budget, manager_id)
VALUES
    ('Finance', 85000, NULL),
    ('Marketing', 95000, NULL),
    ('Research', 110000, NULL);

INSERT INTO employees
    (first_name, last_name, department, salary, hire_date)
VALUES
    ('William', 'Harris', 'Finance', 50000 * 1.1, CURRENT_DATE);

CREATE TEMP TABLE temp_employees (
    emp_id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20)
);

INSERT INTO temp_employees
SELECT
    emp_id,
    first_name,
    last_name,
    department,
    salary,
    hire_date,
    status
FROM employees
WHERE department = 'IT';

SELECT * FROM temp_employees;

UPDATE employees
SET salary = salary * 1.10;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

UPDATE employees
SET department =
    CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (
    SELECT CAST(AVG(e.salary) * 1.20 AS INTEGER)
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department = d.dept_name
);

UPDATE employees
SET
    salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees
    (first_name, last_name, salary, department, hire_date)
VALUES
    ('Thomas', 'Jackson', NULL, NULL, '2025-03-01');

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

INSERT INTO employees
    (first_name, last_name, department, salary, hire_date)
VALUES
    ('Christopher', 'White', 'Senior', 70000, CURRENT_DATE)
RETURNING
    emp_id,
    first_name || ' ' || last_name AS full_name;

WITH updated AS (
    SELECT
        emp_id,
        salary AS old_salary
    FROM employees
    WHERE department = 'IT'
)
UPDATE employees e
SET salary = e.salary + 5000
FROM updated u
WHERE e.emp_id = u.emp_id
RETURNING
    e.emp_id,
    u.old_salary,
    e.salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees
    (first_name, last_name, department, salary, hire_date)
SELECT
    'John',
    'Smith',
    'Senior',
    70000,
    CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'John'
      AND last_name = 'Smith'
);

UPDATE employees e
SET salary =
    CASE
        WHEN d.budget > 100000 THEN e.salary * 1.10
        ELSE e.salary * 1.05
    END
FROM departments d
WHERE e.department = d.dept_name;

INSERT INTO employees
    (first_name, last_name, department, salary, hire_date)
VALUES
    ('Alex', 'Walker', 'Senior', 60000, CURRENT_DATE),
    ('Andrew', 'Hall', 'Senior', 62000, CURRENT_DATE),
    ('Sophia', 'Allen', 'Junior', 45000, CURRENT_DATE),
    ('Mia', 'Young', 'Junior', 47000, CURRENT_DATE),
    ('Ethan', 'King', 'Management', 85000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE (first_name, last_name) IN (
    ('Alex', 'Walker'),
    ('Andrew', 'Hall'),
    ('Sophia', 'Allen'),
    ('Mia', 'Young'),
    ('Ethan', 'King')
);

CREATE TABLE employee_archive (
    emp_id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(20),
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO employee_archive
    (emp_id, first_name, last_name, department,
     salary, hire_date, status)
SELECT
    emp_id,
    first_name,
    last_name,
    department,
    salary,
    hire_date,
    status
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

UPDATE projects p
SET end_date = p.end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
      SELECT COUNT(*)
      FROM employees e
      WHERE e.department = (
          SELECT d.dept_name
          FROM departments d
          WHERE d.dept_id = p.dept_id
      )
  ) > 3;

SELECT * FROM employees;

SELECT * FROM departments;

SELECT * FROM projects;

SELECT * FROM employee_archive;