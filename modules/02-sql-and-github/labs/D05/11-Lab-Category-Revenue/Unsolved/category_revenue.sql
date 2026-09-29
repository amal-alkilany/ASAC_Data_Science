-- ============================================================
-- D05 Lab · Revenue by category, with a join audit
-- Name:
-- ============================================================
--
-- Audit table, Nakheel (fill in as you go)
-- | Step                          | Rows | SUM(qty * price) |
-- |-------------------------------|------|------------------|
-- | order_items alone             |      |                  |
-- | + products                    |      |                  |
-- | + orders                      |      |                  |
-- | completed only                |      |                  |
-- | orders table, completed only  |  –   |                  |  (SUM(order_total))
--
-- Audit table, Pagila
-- | Step                          | Rows | Different films |
-- |-------------------------------|------|-----------------|
-- | film alone                    |      |                 |
-- | + film_category               |      |                 |
-- | + category                    |      |                 |

-- ============================================================
-- C1 · Is product_id unique in products?
-- ============================================================


-- ============================================================
-- C1 · Revenue by category, all orders
-- One row is:
-- Result check:
-- Interpretation:
-- ============================================================


-- ============================================================
-- C2 · Completed revenue by category and month
-- One row is:
-- Result check:
-- Interpretation:
-- ============================================================


-- ============================================================
-- C2 · Completed revenue by category, whole period
-- One row is:
-- Result check:
-- Interpretation:
-- ============================================================


-- ============================================================
-- C3 · Films per category (Pagila)
-- One row is:
-- Result check:
-- Interpretation (why the category counts add up to more than 1,000):
-- ============================================================


-- ============================================================
-- More practice (not checked): X1–X6 from the README
-- ============================================================

