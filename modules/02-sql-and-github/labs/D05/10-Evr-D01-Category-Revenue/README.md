# D01's answer, in SQL

In this activity, you will answer the first question of the programme, "which product category produced the most completed-order revenue last month?", with a three-table join, and check it against the answer you worked out by hand on D01.

**Time:** 20 minutes · **Data:** `D03.order_items`, `D03.orders`, `D03.products` · **Starter:** `Unsolved/d01_category_revenue.sql`

## Instructions

1. Start from `order_items`: it has the amounts. Record its row count and `SUM(qty * price)` in the audit table.

2. Join `orders` to get each line's `status`. Record the rows and the sum again. Did they change? Why not?

3. Join `products` to get each line's `category`. Record them again.

4. Keep completed orders, group by category, and sum `qty * price`.

5. Run it once more without the status filter. Which category wins now?

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| 1 | 1 | 12 rows; 487.00 |
| 2 | 1 | 12 rows; 487.00 |
| 3 | 1 | 12 rows; 487.00 |
| 4 | 3 | Accessories 166.00; Shoes 136.50; Outerwear 84.00 |
| 5 | 3 | Shoes 195.00 |

Query 4 must match D01 exactly: Accessories, 166.00.

## Hint

Each line of `order_items` finds exactly one order and one product, so the joins add columns without adding rows. That is why the audit numbers stay the same. On D01 you saw the other case: leave the cancelled order in and the winner changes.

## References

The D01 tables, course-owned synthetic data, 19 September 2026.
