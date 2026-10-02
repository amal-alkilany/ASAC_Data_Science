-- D08 · 4.2 Everyone Do: The customer and product views
-- One row per customer, cleaned with the D07 rules, and one row per product.
-- You need the bi dataset from Save a query as a view.

-- 1. bi.dim_customer: customer_id, customer_name, city (the D07 CASE rule), segment (LOWER(TRIM(...))), signup_date.
--    No ORDER BY inside a view.


-- 2. bi.dim_product: product_id, product_name, category, list_price, as they are.


-- 4. Check: rows, different customer_id values, segments and cities in bi.dim_customer.
--    Predict:  rows =      customers =      segments =      cities =


-- 5. Check: rows, different product_id values and categories in bi.dim_product.
--    Predict:  rows =      products =      categories =

