# COUNT(*) against COUNT(column) after a LEFT JOIN

In this activity, you will count each customer's orders with a `LEFT JOIN` and see why `COUNT(*)` gives a customer with no orders a count of 1.

**Time:** 10 minutes · **Data:** `nakheel.customers`, `nakheel.orders` · **Starter:** `Unsolved/count_after_left_join.sql`

## Instructions

1. For every customer, show `COUNT(*)` and `COUNT(o.order_id)` from `customers LEFT JOIN orders`. Sort by the order count, smallest first. Look at the first rows.

2. For the whole join, in one row: the number of rows, the number of orders found, and the number of different customers.

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| 1 | 500 | C-1013: `COUNT(*)` 1, `COUNT(o.order_id)` 0 |
| 2 | 1 | 3,038 rows; 2,999 orders; 500 customers |

## Why

A `LEFT JOIN` keeps a customer with no orders as one row, with `NULL` in every order column. `COUNT(*)` counts that row. `COUNT(o.order_id)` skips the `NULL` and gives 0, which is the true number of orders.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../../D04/03-Evr-Upload-Nakheel/Resources/README.md).
