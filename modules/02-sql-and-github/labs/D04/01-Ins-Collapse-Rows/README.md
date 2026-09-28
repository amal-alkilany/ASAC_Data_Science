# Rows collapse into groups

Instructor Do. Tarek adds a calculated column to every row of `D03.order_items`, then groups the same twelve rows two different ways.

**Time:** 18 minutes (2.1 and 2.2) · **Data:** `D03.order_items` · **File:** `Solved/collapse_rows.sql`

## What to notice

- `qty * price AS line_revenue` adds a column. The row count does not change: 12 rows in, 12 rows out.
- `GROUP BY order_id` collapses the 12 rows into 5, one per order. `GROUP BY product_id` collapses the same 12 rows into 5 different groups, one per product.
- **The grain of the result is whatever you group by.** Before you run a `GROUP BY`, say what one row of the answer will be.
- Every column in `SELECT` must be either in the `GROUP BY` or inside a function such as `SUM` or `COUNT`. Otherwise you get: `SELECT list expression references column product_id which is neither grouped nor aggregated`. BigQuery cannot put five different products into one order's row.

| order_id | lines | order_revenue |
|---:|---:|---:|
| 1001 | 2 | 47.00 |
| 1002 | 2 | 100.50 |
| 1003 | 3 | 61.50 |
| 1004 | 2 | 162.00 |
| 1005 | 3 | 116.00 |

## References

The D01 tables, course-owned synthetic data, 19 September 2026.
