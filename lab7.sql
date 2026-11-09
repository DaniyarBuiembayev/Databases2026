-- ============================================================
-- LABORATORY WORK 7: SQL VIEWS AND ROLES
-- PostgreSQL - consolidated script
--
-- Run as a PostgreSQL administrator (normally postgres).
-- Assumes Lab 6 tables already exist:
--   employees(emp_id, emp_name, dept_id, salary)
--   departments(dept_id, dept_name, location)
--   projects(project_id, project_name, budget, dept_id)
--
-- Notes:
-- 1. INSERTs for Alice Johnson and Charlie Brown are guarded so the
--    script can be rerun without duplicate primary-key errors.
-- 2. The intentionally failing CHECK OPTION test is commented out.
--    Run it separately if you need to demonstrate the expected error.
-- 3. Materialized views are dropped and recreated so this script can
--    be rerun. Existing data in those materialized views is recalculated.
-- ============================================================


-- ============================================================
-- PART 2: CREATING BASIC VIEWS
-- ============================================================

-- Exercise 2.1: Simple view
-- Drop an older version first because CREATE OR REPLACE cannot remove columns.
DROP VIEW IF EXISTS employee_details;

CREATE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- Question: How many rows are returned? The exact number depends on
-- Lab 6 data. Tom Brown does not appear if he has no matching department,
-- because INNER JOIN excludes rows without a match.


-- Exercise 2.2: View with aggregation
CREATE OR REPLACE VIEW dept_statistics AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS average_salary,
    MAX(e.salary) AS maximum_salary,
    MIN(e.salary) AS minimum_salary
FROM departments d
LEFT JOIN employees e
    ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT *
FROM dept_statistics
ORDER BY employee_count DESC;

-- LEFT JOIN keeps departments that have no employees.
-- COUNT(e.emp_id) returns 0 for such departments.


-- Exercise 2.3: View with multiple joins
CREATE OR REPLACE VIEW project_overview AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    COUNT(DISTINCT e.emp_id) AS team_size
FROM projects p
JOIN departments d
    ON p.dept_id = d.dept_id
LEFT JOIN employees e
    ON d.dept_id = e.dept_id
GROUP BY
    p.project_id,
    p.project_name,
    p.budget,
    d.dept_name,
    d.location;

SELECT * FROM project_overview;


-- Exercise 2.4: View with filtering
-- Remove the renamed view from a previous run, if it exists, so that
-- Exercise 3.2 can rename high_earners again.
DROP VIEW IF EXISTS top_performers;

CREATE OR REPLACE VIEW high_earners AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name
FROM employees e
JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;

-- Only employees earning more than 55000 and having a matching
-- department appear in this view.


-- ============================================================
-- PART 3: MODIFYING AND MANAGING VIEWS
-- ============================================================

-- Exercise 3.1: Replace a view
CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
    END AS salary_grade
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;


-- Exercise 3.2: Rename a view
ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;


-- Exercise 3.3: Create and drop a temporary view
CREATE OR REPLACE VIEW temp_view AS
SELECT *
FROM employees
WHERE salary < 50000;

SELECT * FROM temp_view;

DROP VIEW temp_view;


-- ============================================================
-- PART 4: UPDATABLE VIEWS
-- ============================================================

-- Exercise 4.1: Create an updatable view
CREATE OR REPLACE VIEW employee_salaries AS
SELECT
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees;


-- Exercise 4.2: Update through a view
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT *
FROM employees
WHERE emp_name = 'John Smith';

-- Yes. A simple updatable view forwards the UPDATE to its base table.


-- Exercise 4.3: Insert through a view
-- The NOT EXISTS condition prevents a duplicate emp_id if the script
-- is executed again.
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
SELECT 6, 'Alice Johnson', 102, 58000
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE emp_id = 6
);

SELECT *
FROM employees
WHERE emp_id = 6;

-- The insert succeeds if emp_id 6 is unused and dept_id 102 exists
-- (and all other table constraints are satisfied).


-- Exercise 4.4: View with LOCAL CHECK OPTION
CREATE OR REPLACE VIEW it_employees AS
SELECT *
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- This INSERT is intentionally commented out because it is expected
-- to fail and would stop a single-script execution in many SQL clients.
-- To test the error, run this statement separately:
--
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
-- VALUES (7, 'Bob Wilson', 103, 60000);
--
-- Expected result: an error because dept_id 103 does not satisfy
-- the view condition dept_id = 101. CHECK OPTION rejects the row.


-- ============================================================
-- PART 5: MATERIALIZED VIEWS
-- ============================================================

-- Exercise 5.1: Create a materialized view
-- Drop previous versions (and their indexes) to make this script rerunnable.
DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv CASCADE;

-- Scalar subqueries prevent duplicated sums when a department has
-- multiple employees and multiple projects.
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    d.dept_id,
    d.dept_name,
    (
        SELECT COUNT(*)
        FROM employees e
        WHERE e.dept_id = d.dept_id
    ) AS total_employees,
    COALESCE(
        (
            SELECT SUM(e.salary)
            FROM employees e
            WHERE e.dept_id = d.dept_id
        ), 0
    ) AS total_salaries,
    (
        SELECT COUNT(*)
        FROM projects p
        WHERE p.dept_id = d.dept_id
    ) AS total_projects,
    COALESCE(
        (
            SELECT SUM(p.budget)
            FROM projects p
            WHERE p.dept_id = d.dept_id
        ), 0
    ) AS total_project_budget
FROM departments d
WITH DATA;

SELECT *
FROM dept_summary_mv
ORDER BY total_employees DESC;


-- Exercise 5.2: Refresh materialized view
-- Insert Charlie Brown only if emp_id 8 is not already present.
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
SELECT 8, 'Charlie Brown', 101, 54000
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE emp_id = 8
);

-- Before refresh, the materialized view still contains its previous snapshot.
SELECT * FROM dept_summary_mv;

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- After refresh, the materialized view reflects the current employees data.
SELECT * FROM dept_summary_mv;


-- Exercise 5.3: Concurrent refresh
CREATE UNIQUE INDEX dept_summary_mv_dept_id_idx
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

-- CONCURRENTLY allows SELECT queries to continue reading the
-- materialized view while the refresh is in progress.


-- Exercise 5.4: Materialized view WITH NO DATA
DROP MATERIALIZED VIEW IF EXISTS project_stats_mv CASCADE;

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(DISTINCT e.emp_id) AS employee_count
FROM projects p
JOIN departments d
    ON p.dept_id = d.dept_id
LEFT JOIN employees e
    ON d.dept_id = e.dept_id
GROUP BY
    p.project_id,
    p.project_name,
    p.budget,
    d.dept_name
WITH NO DATA;

-- This SELECT is expected to fail before the first refresh:
-- SELECT * FROM project_stats_mv;
--
-- Expected error: materialized view has not been populated.
-- Populate it, then query it:
REFRESH MATERIALIZED VIEW project_stats_mv;

SELECT * FROM project_stats_mv;


-- ============================================================
-- PART 6: DATABASE ROLES
-- ============================================================

-- Role creation is conditional so that an "already exists" error
-- does not interrupt a rerun. Existing roles are retained.


-- Exercise 6.1: Basic roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analyst') THEN
        CREATE ROLE analyst;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'data_viewer') THEN
        CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'report_user') THEN
        CREATE USER report_user WITH PASSWORD 'report456';
    END IF;
END
$$;

SELECT rolname
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%'
ORDER BY rolname;


-- Exercise 6.2: Roles with specific attributes
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'db_creator') THEN
        CREATE ROLE db_creator LOGIN CREATEDB PASSWORD 'creator789';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'user_manager') THEN
        CREATE ROLE user_manager LOGIN CREATEROLE PASSWORD 'manager101';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_user') THEN
        CREATE ROLE admin_user LOGIN SUPERUSER PASSWORD 'admin999';
    END IF;
END
$$;


-- Exercise 6.3: Grant privileges
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;


-- Exercise 6.4: Group roles and members
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hr_team') THEN
        CREATE ROLE hr_team;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'finance_team') THEN
        CREATE ROLE finance_team;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'it_team') THEN
        CREATE ROLE it_team;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hr_user1') THEN
        CREATE USER hr_user1 WITH PASSWORD 'hr001';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hr_user2') THEN
        CREATE USER hr_user2 WITH PASSWORD 'hr002';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'finance_user1') THEN
        CREATE USER finance_user1 WITH PASSWORD 'fin001';
    END IF;
END
$$;

GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;


-- Exercise 6.5: Revoke privileges
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;


-- Exercise 6.6: Modify role attributes
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;


-- ============================================================
-- PART 7: ADVANCED ROLE MANAGEMENT
-- ============================================================

-- Exercise 7.1: Role hierarchy
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'read_only') THEN
        CREATE ROLE read_only;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'junior_analyst') THEN
        CREATE USER junior_analyst WITH PASSWORD 'junior123';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'senior_analyst') THEN
        CREATE USER senior_analyst WITH PASSWORD 'senior123';
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;
GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;


-- Exercise 7.2: Object ownership
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'project_manager') THEN
        CREATE USER project_manager WITH PASSWORD 'pm123';
    END IF;
END
$$;

-- The new owner needs CREATE on the schema. Run this section as postgres
-- (or another sufficiently privileged role).
GRANT USAGE, CREATE ON SCHEMA public TO project_manager;

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

-- The owner of dept_statistics must be able to read its source tables.
GRANT SELECT ON employees, departments, projects TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;


-- Exercise 7.3: Reassign and drop role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'temp_owner') THEN
        CREATE ROLE temp_owner LOGIN;
    END IF;
END
$$;

DROP TABLE IF EXISTS temp_table;

CREATE TABLE temp_table (
    id INT
);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO daniyar;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;


-- Exercise 7.4: Role-specific views
CREATE OR REPLACE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;


CREATE OR REPLACE VIEW finance_employee_view AS
SELECT
    emp_id,
    emp_name,
    salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


-- ============================================================
-- PART 8: PRACTICAL SCENARIOS
-- ============================================================

-- Exercise 8.1: Department dashboard
-- The supplied Lab 6 schema does not specify a project status column.
-- Therefore, this query counts all projects. If a status column exists,
-- add a condition such as WHERE status = 'active' in the project subquery.
CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
    d.dept_name,
    d.location,
    COALESCE(e.employee_count, 0) AS employee_count,
    COALESCE(e.average_salary, 0) AS average_salary,
    COALESCE(p.active_projects, 0) AS active_projects,
    COALESCE(p.total_project_budget, 0) AS total_project_budget,
    CASE
        WHEN COALESCE(e.employee_count, 0) = 0 THEN 0
        ELSE ROUND(
            COALESCE(p.total_project_budget, 0) / e.employee_count,
            2
        )
    END AS budget_per_employee
FROM departments d
LEFT JOIN (
    SELECT
        dept_id,
        COUNT(*) AS employee_count,
        ROUND(AVG(salary), 2) AS average_salary
    FROM employees
    GROUP BY dept_id
) e
    ON d.dept_id = e.dept_id
LEFT JOIN (
    SELECT
        dept_id,
        COUNT(*) AS active_projects,
        SUM(budget) AS total_project_budget
    FROM projects
    GROUP BY dept_id
) p
    ON d.dept_id = p.dept_id;

SELECT * FROM dept_dashboard;


-- Exercise 8.2: Audit view
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,
    CASE
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
    END AS approval_status
FROM projects p
JOIN departments d
    ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;


-- Exercise 8.3: Complete access control hierarchy
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'viewer_role') THEN
        CREATE ROLE viewer_role;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'entry_role') THEN
        CREATE ROLE entry_role;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analyst_role') THEN
        CREATE ROLE analyst_role;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'manager_role') THEN
        CREATE ROLE manager_role;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'alice') THEN
        CREATE USER alice WITH PASSWORD 'alice123';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bob') THEN
        CREATE USER bob WITH PASSWORD 'bob123';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'charlie') THEN
        CREATE USER charlie WITH PASSWORD 'charlie123';
    END IF;
END
$$;

-- Level 1: Viewer
GRANT USAGE ON SCHEMA public TO viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

-- Level 2: Entry
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3: Analyst
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4: Manager
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Assign users to their respective access levels
GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;


-- ============================================================
-- FINAL VERIFICATION
-- ============================================================

SELECT
    rolname,
    rolsuper,
    rolcreatedb,
    rolcreaterole,
    rolcanlogin
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%'
ORDER BY rolname;

SELECT * FROM employee_details;
SELECT * FROM dept_statistics;
SELECT * FROM project_overview;
SELECT * FROM top_performers;
SELECT * FROM dept_summary_mv;
SELECT * FROM project_stats_mv;
SELECT * FROM dept_dashboard;
SELECT * FROM high_budget_projects;

-- ============================================================
-- END OF LABORATORY WORK 7
-- ============================================================
