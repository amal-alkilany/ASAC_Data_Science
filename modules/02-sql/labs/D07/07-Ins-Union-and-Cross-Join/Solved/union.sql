-- D07 · 4.1 Instructor Do: UNION ALL and UNION DISTINCT
-- A join adds columns side by side. UNION stacks the rows of two queries into one result.
-- Both queries must return the same number of columns, in the same order, with matching types.
-- The result takes its column names from the first query.

-- Q1: customers in Amman (2 rows: C-118, C-377). C-455 has no city, so = 'Amman' does not keep it.
-- @check Union 1
SELECT customer_id
FROM D03.customers
WHERE city = 'Amman';

-- Q2: the customer on each completed order (4 rows: C-204 twice, C-401, C-118).
-- @check Union 2
SELECT customer_id
FROM D03.orders
WHERE status = 'completed';

-- UNION ALL keeps every row: 2 + 4 = 6. The row count is always rows in Q1 + rows in Q2.
-- @check Union 3
SELECT customer_id
FROM D03.customers
WHERE city = 'Amman'
UNION ALL
SELECT customer_id
FROM D03.orders
WHERE status = 'completed';

-- UNION DISTINCT keeps each row once: 4. It removes C-118 (in both queries)
-- AND the second C-204 (a repeat inside Q2). Row order is not guaranteed, so sort it.
-- @check Union 4
SELECT customer_id
FROM D03.customers
WHERE city = 'Amman'
UNION DISTINCT
SELECT customer_id
FROM D03.orders
WHERE status = 'completed'
ORDER BY customer_id;

-- This one fails on purpose. BIGQUERY-SPECIFIC: a bare UNION is a syntax error in BigQuery:
--   Syntax error: Expected keyword ALL or keyword DISTINCT but got keyword SELECT
-- Most other databases (PostgreSQL, SQL Server, MySQL, Snowflake) accept a bare UNION and read it as DISTINCT.
-- @skip error on purpose: BigQuery rejects a bare UNION
SELECT customer_id
FROM D03.customers
WHERE city = 'Amman'
UNION
SELECT customer_id
FROM D03.orders
WHERE status = 'completed';
