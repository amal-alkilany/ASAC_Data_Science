-- D08 · 4.2 Everyone Do: The customer and product views
-- One row per customer, cleaned with the D07 rules, and one row per product.

-- Creates the view; the next query checks it.
CREATE OR REPLACE VIEW bi.dim_customer AS
SELECT customer_id,
       customer_name,
       CASE
         WHEN city IS NULL THEN 'unknown'
         WHEN LOWER(TRIM(city)) = 'al zarqa' THEN 'zarqa'
         ELSE LOWER(TRIM(city))
       END AS city,
       LOWER(TRIM(segment)) AS segment,
       signup_date
FROM nakheel.customers;

-- Creates the view; the next query checks it.
CREATE OR REPLACE VIEW bi.dim_product AS
SELECT product_id,
       product_name,
       category,
       list_price
FROM nakheel.products;

-- Step 4. Check: one row per customer, 2 segments, 9 city values (8 cities and unknown). (1 row: 500, 500, 2, 9)
-- @check 4
SELECT COUNT(*) AS customer_rows,
       COUNT(DISTINCT customer_id) AS different_customers,
       COUNT(DISTINCT segment) AS segments,
       COUNT(DISTINCT city) AS cities
FROM bi.dim_customer;

-- Step 5. Check: one row per product, 6 categories. (1 row: 60, 60, 6)
-- @check 5
SELECT COUNT(*) AS product_rows,
       COUNT(DISTINCT product_id) AS different_products,
       COUNT(DISTINCT category) AS categories
FROM bi.dim_product;
