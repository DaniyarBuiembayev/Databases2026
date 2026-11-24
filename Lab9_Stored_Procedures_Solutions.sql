-- ============================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Part 1: Database Setup  (CityBike rental network)
-- ============================================================

DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

-- Create table: stations
CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

-- Create table: bikes
CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

-- Create table: members
CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

-- Create table: rentals
CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
 (10, 'Central Park', 'Almaty',   4),
 (20, 'Riverside',    'Almaty',   3),
 (30, 'Expo Gate',    'Astana',   5),
 (40, 'Old Town',     'Shymkent', 2),
 (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
 (101, 'City Cruiser', 10,  4.50),
 (102, 'City Cruiser', 10,  4.50),
 (103, 'Mountain X',   20,  7.00),
 (104, 'Mountain X',   30,  7.00),
 (105, 'Road Sprint',  30,  9.25),
 (106, 'Folding Mini', 40,  3.75),
 (107, 'Cargo Hauler', 20, 12.00),
 (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
 (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
 (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
 (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
 (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
 (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
 (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
 ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
 ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
 ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
 ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
 ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
 ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
 ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
 ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
 ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
 (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
 (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
 (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
 (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
 (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
 (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
 (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
 (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
 (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
 (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
 (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
 (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
 (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);

-- ============================================================
-- Laboratory Work 9: Stored Procedures and User-Defined Functions
-- Parts 2-7: Complete solutions and test calls
-- PostgreSQL / PLpgSQL
-- ============================================================

-- ============================================================
-- PART 2: YOUR FIRST FUNCTION
-- ============================================================

-- Exercise 2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);
SELECT rental_days(11);
SELECT rental_days(19);   -- NULL: rental is still open
SELECT rental_days(999);  -- NULL: rental does not exist

-- Exercise 2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);
SELECT member_rental_count(5);
SELECT member_rental_count(6);
SELECT member_rental_count(99);

-- Exercise 2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR(40);
BEGIN
    SELECT city
    INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30);
SELECT station_city(77);

-- Exercise 2.4
SELECT
    rental_id,
    member_id,
    rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC;


-- ============================================================
-- PART 3: PARAMETER MODES
-- ============================================================

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(
    p_fee NUMERIC,
    p_percent NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE
) AS $$
BEGIN
    SELECT
        COUNT(*)::INT,
        COALESCE(SUM(r.fee), 0),
        MAX(r.start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals r
    WHERE r.member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);

-- Exercise 3.3: INOUT parameter
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee)
FROM rentals
WHERE rental_id = 1;

-- Exercise 3.4: VARIADIC parameter
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC
) AS $$
BEGIN
    SELECT
        COALESCE(SUM(p_fees[g.i]), 0),
        ROUND(AVG(p_fees[g.i]), 2),
        MAX(p_fees[g.i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) AS g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
SELECT * FROM fee_summary();

-- Exercise 3.5: Choosing a mode
-- (a) IN       - the station id is supplied only as input.
-- (b) INOUT    - the caller supplies a balance and receives its updated value.
-- (c) VARIADIC - the caller can supply a variable number of station ids.
-- (d) OUT      - multiple statistics can be returned from one function call.


-- ============================================================
-- PART 4: DEFAULT VALUES AND FUNCTION OVERLOADING
-- ============================================================

-- Exercise 4.1: One-parameter version
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1);
SELECT total_fees(6);

-- Exercise 4.2: Two-parameter overloaded version
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');

-- Exercise 4.3: Add a default value.
-- The one-argument overload still exists, so total_fees(1) becomes ambiguous.
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01'
)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Demonstrate and catch the expected ambiguity error without stopping the script.
DO $$
BEGIN
    BEGIN
        EXECUTE 'SELECT total_fees(1)';
    EXCEPTION
        WHEN ambiguous_function THEN
            RAISE NOTICE 'Expected Exercise 4.3 error: %', SQLERRM;
    END;
END;
$$;

-- Exercise 4.4: Remove the one-argument version to resolve ambiguity.
DROP FUNCTION total_fees(INTEGER);

SELECT total_fees(1);

-- Exercise 4.5: Overload by argument type.
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
    INTO v_total
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.full_name = p_member_name;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);


-- ============================================================
-- PART 5: FUNCTIONS THAT RETURN A TABLE
-- ============================================================

-- Exercise 5.1: Search by pattern
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (
    found_id INT,
    found_model VARCHAR,
    found_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.bike_id,
        b.model::VARCHAR,
        b.daily_rate
    FROM bikes b
    WHERE b.model ILIKE p_pattern
    ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');

-- Exercise 5.2: Table from a join
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (
    history_rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    duration_days INT,
    rental_fee NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.rental_id,
        b.model::VARCHAR,
        s.station_name::VARCHAR,
        (r.end_date - r.start_date)::INT,
        r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    LEFT JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);

-- Exercise 5.3: The unqualified column names in this version are ambiguous
-- when the function is called. Catch the expected error for demonstration.
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model
    FROM bikes
    WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    BEGIN
        PERFORM * FROM bike_list(10);
    EXCEPTION
        WHEN ambiguous_column THEN
            RAISE NOTICE 'Expected Exercise 5.3 error: %', SQLERRM;
    END;
END;
$$;

-- Fix 1: Rename the output columns.
CREATE OR REPLACE FUNCTION bike_list_renamed(p_station_id INT)
RETURNS TABLE (found_bike_id INT, found_model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR
    FROM bikes b
    WHERE b.station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list_renamed(10);

-- Fix 2: Keep the output names and qualify table columns with an alias.
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model::VARCHAR
    FROM bikes AS b
    WHERE b.station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Exercise 5.4: Station board
-- COUNT(*) returns BIGINT, so it is explicitly cast to INT.
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (
    s_name VARCHAR,
    s_bikes INT,
    s_free INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.station_name::VARCHAR,
        COUNT(b.bike_id)::INT,
        (s.capacity - COUNT(b.bike_id)::INT)::INT
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');


-- ============================================================
-- PART 6: BLOCK STRUCTURE, DO BLOCKS AND SUBBLOCKS
-- ============================================================

-- Exercise 6.1: Labelled anonymous block
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*)::INTEGER
    INTO total_rentals
    FROM rentals;

    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report;
$$;

-- Exercise 6.2: Subblock and shadowed variable
DO $$
<<rental_report>>
DECLARE
    fee_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO fee_total
    FROM rentals;

    RAISE NOTICE 'Outer total before subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT COALESCE(SUM(fee), 0)
        INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';

        RAISE NOTICE 'Subblock total: %', fee_total;
        RAISE NOTICE 'Outer total from subblock: %', rental_report.fee_total;
    END;

    RAISE NOTICE 'Outer total after subblock: %', fee_total;
END rental_report;
$$;

-- Exercise 6.3: A variable declared in one subblock is not visible
-- in a later sibling subblock. The following intentionally invalid
-- example is kept as a comment so the complete script remains executable:
--
-- DO $$
-- BEGIN
--     DECLARE
--         first_only INTEGER := 10;
--     BEGIN
--         RAISE NOTICE '%', first_only;
--     END;
--
--     DECLARE
--     BEGIN
--         RAISE NOTICE '%', first_only; -- ERROR: variable is not declared here
--     END;
-- END;
-- $$;
--
-- Correct approach: declare the variable in the outer block.
DO $$
DECLARE
    shared_value INTEGER := 10;
BEGIN
    BEGIN
        RAISE NOTICE 'First subblock sees shared_value = %', shared_value;
    END;

    BEGIN
        RAISE NOTICE 'Second subblock sees shared_value = %', shared_value;
    END;
END;
$$;

-- Exercise 6.4: Convert the split calculation into a stored function.
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC
) AS $$
BEGIN
    SELECT
        COALESCE(SUM(fee) FILTER (WHERE start_date < p_from_date), 0),
        COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
    INTO before_total, after_total
    FROM rentals;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');

SELECT
    (SELECT before_total + after_total
     FROM fee_split(DATE '2025-01-01')) AS split_total,
    (SELECT COALESCE(SUM(fee), 0) FROM rentals) AS whole_table_total;


-- ============================================================
-- PART 7: PRACTICAL SCENARIOS
-- ============================================================

-- Exercise 7.1: Station occupancy
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC
) AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT s.capacity, COUNT(b.bike_id)::INT
    INTO v_capacity, bikes_parked
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.station_id = p_station_id
    GROUP BY s.capacity;

    IF NOT FOUND THEN
        bikes_parked := 0;
        capacity_pct := NULL;
    ELSIF v_capacity = 0 THEN
        capacity_pct := NULL;
    ELSE
        capacity_pct := ROUND((bikes_parked::NUMERIC / v_capacity) * 100, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT station_load(10);
SELECT station_load(50);

SELECT
    s.station_id,
    s.station_name,
    l.*
FROM stations s,
LATERAL station_load(s.station_id) l
ORDER BY s.station_id;

-- Exercise 7.2: Top members, with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (
    member_name VARCHAR,
    rental_count BIGINT,
    total_spent NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.full_name::VARCHAR,
        COUNT(r.rental_id),
        COALESCE(SUM(r.fee), 0)::NUMERIC
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY COALESCE(SUM(r.fee), 0) DESC, m.full_name
    LIMIT GREATEST(p_limit, 0);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);

-- Exercise 7.3: Invoice for a closed or open rental
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (
    member_name VARCHAR,
    bike_model VARCHAR,
    rental_days_count INT,
    amount_owed NUMERIC,
    rental_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.full_name::VARCHAR,
        b.model::VARCHAR,
        CASE
            WHEN r.end_date IS NULL THEN (CURRENT_DATE - r.start_date)::INT
            ELSE (r.end_date - r.start_date)::INT
        END,
        ROUND(
            (CASE
                WHEN r.end_date IS NULL THEN CURRENT_DATE - r.start_date
                ELSE r.end_date - r.start_date
             END)::NUMERIC * b.daily_rate,
            2
        ),
        CASE
            WHEN r.end_date IS NULL THEN 'OPEN'::VARCHAR
            ELSE 'CLOSED'::VARCHAR
        END
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);

-- Exercise 7.4: Report per city
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT m.member_id),
        COUNT(r.rental_id),
        COALESCE(SUM(r.fee), 0)::NUMERIC
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(
    p_city VARCHAR,
    p_from_date DATE
)
RETURNS TABLE (
    member_count BIGINT,
    rental_count BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(DISTINCT m.member_id),
        COUNT(r.rental_id),
        COALESCE(SUM(r.fee), 0)::NUMERIC
    FROM members m
    LEFT JOIN rentals r
        ON r.member_id = m.member_id
       AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
SELECT * FROM city_report('Astana');
SELECT * FROM city_report('Astana', DATE '2025-01-01');

-- Comparison: putting the date predicate in WHERE removes members
-- without qualifying rentals, effectively changing the LEFT JOIN result.
SELECT
    COUNT(DISTINCT m.member_id) AS members_with_date_in_where,
    COUNT(r.rental_id) AS rentals_after_date
FROM members m
LEFT JOIN rentals r ON r.member_id = m.member_id
WHERE m.city = 'Almaty'
  AND r.start_date >= DATE '2025-01-01';


-- ============================================================
-- END OF LABORATORY WORK 9
-- ============================================================
