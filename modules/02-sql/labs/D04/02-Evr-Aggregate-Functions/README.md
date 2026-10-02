# Aggregate functions

In this activity, you will turn many rows into one number with each aggregate function, and check each answer against the D01 worksheet you did by hand, or against the rows on screen where the worksheet has no figure.

**Time:** 12 minutes · **Data:** `D03` tables · **Starter:** `Unsolved/aggregate_functions.sql`

## Instructions

1. Count the orders. Predict first.
2. Count the customer rows, and the customer rows that have a city, in one query.
3. Count the orders, and the different customer IDs that placed them.
4. In one query on `order_items`: total revenue (`SUM(qty * price)`), average unit price, cheapest and dearest unit.
5. The first and last order dates.

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| 1 | 1 | 5 |
| 2 | 1 | 5 rows, 4 with a city |
| 3 | 1 | 5 orders, 3 customer IDs |
| 4 | 1 | revenue 487.00; average unit price 21.08 |
| 5 | 1 | 2026-08-03 to 2026-08-24 |

## Hint

`COUNT(*)` counts rows. `COUNT(city)` counts rows where `city` is not `NULL`. `COUNT(DISTINCT customer_id)` counts different values.

## Bonus

The D01 worksheet said completed revenue was 386.50. Query 4 says 487.00. Which order explains the difference, and how much is it worth?

## References

The D01 tables, course-owned synthetic data, 19 September 2026.
