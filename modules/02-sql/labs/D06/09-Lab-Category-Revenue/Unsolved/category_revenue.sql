-- ============================================================
-- D06 · 5.2 Lab: Revenue by category, with a join audit
-- Name:
-- ============================================================
--
-- Audit table (fill in as you go)
-- | Step                          | Rows | SUM(qty * price) |
-- |-------------------------------|------|------------------|
-- | order_items alone             |      |                  |
-- | + products                    |      |                  |
-- | + orders                      |      |                  |
-- | completed only                |      |                  |
-- | orders table, completed only  |  –   |                  |  (SUM(order_total))

-- ============================================================
-- C1 · Two tables: revenue by category (order_items + products)
-- ============================================================

-- Step 1. Is product_id unique in products?


-- Step 2. Audit, before: order_items alone (rows and SUM(qty * price)).


-- Step 3. Audit, after order_items INNER JOIN products.


-- Step 4. Revenue by category, all orders.
-- One row is:
-- Result check:
-- Interpretation:


-- ============================================================
-- C2 · Three tables: completed revenue by category, whole period
-- ============================================================

-- Step 5. Audit, after joining orders as well.


-- Step 6. Audit, completed orders only.


-- Step 7. Cross-check: SUM(order_total) for completed orders on the orders table alone.


-- Step 8. Completed revenue by category, whole period.
-- One row is:
-- Result check:
-- Interpretation:


-- ============================================================
-- C3 · Completed revenue by category and month
-- ============================================================

-- Step 9. Completed revenue by category and month.
-- One row is:
-- Result check:
-- Interpretation:


-- ============================================================
-- More practice (not checked): X1–X3 from the README
-- ============================================================

