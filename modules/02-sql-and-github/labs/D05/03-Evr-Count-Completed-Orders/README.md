# How many completed orders?

In this activity, you will answer one question on one table, then again after a join, and find out why the second answer is wrong even though the join is right.

**Time:** 8 minutes · **Data:** `D03.orders`, `D03.order_items` · **Starter:** `Unsolved/count_completed_orders.sql`

## Instructions

1. "How many completed orders do we have?" Count them on `D03.orders`.

2. Join `D03.order_items` to `D03.orders` on `order_id`, keep completed orders, and count the rows again.

3. Say what one row is after the join. Change the count so it answers the question.

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| 1 | 1 | 4 |
| 2 | 1 | 10 |
| 3 | 1 | 4 |

## Why 10 is wrong

Nothing is wrong with the join. After it, one row is one product on one order, so `COUNT(*)` counts order lines. The question asked for orders. The grain changed, and the count followed it. `COUNT(DISTINCT o.order_id)` counts orders again.

## References

The D01 tables, course-owned synthetic data, 19 September 2026.
