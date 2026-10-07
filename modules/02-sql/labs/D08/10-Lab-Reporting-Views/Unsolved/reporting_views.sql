-- ============================================================
-- D08 · 5.3 Lab: Reporting views for Power BI and for D10
-- Name:
-- ============================================================
--
-- Audit table (fill in as you go). Rows = rows in the table or view; for the last line, the order lines the join returns.
-- | Audit                                               | Rows | Completed orders or lines | Revenue |
-- |-----------------------------------------------------|------|---------------------------|---------|
-- | orders, completed only (known since D06)            | 2,771 | 2,771 orders             | 316,023.50 |
-- | bi.customer_summary                                 |      |                           |         |
-- | bi.category_month                                   |      |            –              |         |
-- | fact_sales INNER JOIN dim_customer_complete, compl. |      |                           |         |

-- ============================================================
-- C1 · Step 1. bi.customer_summary: one row per customer, built on bi.dim_customer
-- Columns: customer_id, customer_name, segment, city, completed_orders, revenue, first_order, last_order
-- ============================================================


-- ============================================================
-- C1 · Step 2. Audit: customers, completed orders, revenue, customers with none
-- Result check:
-- ============================================================


-- ============================================================
-- C2 · Step 3. bi.category_month: completed units and revenue by category and month
-- ============================================================


-- ============================================================
-- C2 · Step 4. Audit: rows and total revenue
-- Rows expected (categories x months):
-- Result check:
-- ============================================================


-- ============================================================
-- C3 · Step 5. bi.dim_customer_complete: every customer, plus one 'unknown' row
-- for each customer_id that has orders but no customer record
-- Columns: customer_id, customer_name, city, segment, signup_date
-- ============================================================


-- ============================================================
-- C3 · Step 6. Audit: fact_sales INNER JOIN dim_customer_complete, completed lines and revenue.
-- Then read the whole view with SELECT * and count its rows (6b)
-- Result check:
-- ============================================================


-- ============================================================
-- Stretch card S1 (not checked): bi.segment_month
-- ============================================================


-- ============================================================
-- More practice (not checked): X1–X3 from the README
-- ============================================================

