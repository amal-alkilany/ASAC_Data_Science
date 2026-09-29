# Lab: Revenue by category, with a join audit

In this lab, you will answer the question the D04 managers could not get answered, "which product category brings in the most revenue?", prove with an audit table that no join changed the total, and then use the same method on a film database where a join does multiply rows.

**Time:** 35 minutes · **Data:** `nakheel.order_items`, `nakheel.products`, `nakheel.orders`; `pagila.film`, `pagila.film_category`, `pagila.category` · **Starter:** `Unsolved/category_revenue.sql`

**Before you start:** the four `nakheel` tables are uploaded. If they are missing, use the [D04 Nakheel upload activity](../../D04/03-Evr-Upload-Nakheel/README.md). For C3 you also upload three Pagila files (step 9).

**What you hand in:** nothing. Save your `.sql` file with the audit tables filled in. It is the third file you choose from for Assignment 1 on D08.

## The audit table

After every join, record three numbers, and say whether each should have changed:

| Step | Rows | Different orders (or films) | Total you care about |
|---|---:|---:|---:|
| before the join | | | |
| after join 1 | | | |
| after join 2 | | | |
| after the filter | | | |

If a number changed and you cannot say why, stop and find out before you go on.

## C1 · Two tables: revenue by category

1. Five Checks for `order_items` and `products`. Is `product_id` unique in `products`? Prove it with `COUNT(*)` and `COUNT(DISTINCT product_id)`.
2. Audit, before: rows in `order_items` and `SUM(qty * price)`.
3. Audit, after `order_items INNER JOIN products`: the same two numbers.
4. "Which product category has brought in the most revenue?" All orders for now. Group by `category`.

**Checkpoint C1:** the audit shows 7,516 rows and 340,370.00 before and after, and the query returns 6 categories.

## C2 · Three tables: completed orders by category and month

5. Join `orders` as well, to get `status` and `order_date`. Audit: rows and total.
6. Keep completed orders only. Audit again. Then check the total against the orders table on its own: `SUM(order_total)` for completed orders. The two must be equal.
7. "Show me completed revenue for each category, month by month."

    Translate: completed orders; group by category and by `DATE_TRUNC(o.order_date, MONTH)`.

8. "And for the whole two years, which category is top?"

**Checkpoint C2:** the completed total after the joins equals the orders table's completed total, and your month-by-category result has 144 rows.

## C3 · A new sector, the same method: films per category

Pagila is a sample database for a DVD rental shop. One film can belong to more than one category, so the link between films and categories is kept in a third table, `film_category`, with one row per film per category. A table that sits between two others like this is called a **bridge table**.

9. Save `film.csv`, `category.csv` and `film_category.csv` from `Resources/` to your laptop. On GitHub, use **Download raw file** for each; in a zip they are already inside the activity folder. Create a dataset `pagila` in **Multi-region US**. From its **⋮** menu, choose **Create table** and upload each CSV as a table with the same name without `.csv`. Tick **Auto detect** and set **Header rows to skip** to `1` under Advanced options.
10. Audit: rows in `film`. Then rows and different films after `film INNER JOIN film_category`.
11. "How many films do we have in each category?" Join `category` as well, and group by its `name`.
12. Add up your category counts in your head or on paper. Compare with the number of films. In your interpretation line, explain the difference, and say what would go wrong if someone summed `rental_rate` by category and called it "the catalogue's total".

**Checkpoint C3:** your audit explains why 1,000 films become 2,367 rows.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 1 | 60 and 60: unique |
| 2 | 1 | 7,516 rows; 340,370.00 |
| 3 | 1 | 7,516 rows; 340,370.00 |
| 4 | 6 | Outerwear first, 81,920.50 |
| 5 | 1 | 7,516 rows; 340,370.00 |
| 6 | 1 | 6,951 rows; 316,023.50 |
| 6b | 1 | 316,023.50 |
| 7 | 144 | September 2024, Outerwear: 3,068.00 |
| 8 | 6 | Outerwear first, 76,637.00 |
| 10 | 1 | 1,000 |
| 10b | 1 | 2,367 rows; 1,000 films |
| 11 | 16 | Drama and Music, 152 each |
| 12 | 3 | 403 films have 3 categories |

Row 12 is the query behind step 12's explanation: how many categories each film has. It needs a subquery, so it is in the Solved file for the Review rather than asked of you.

If an audit number changes unexpectedly, check the `ON` condition and the source of the amount before grouping.

## Hint

In C2, write the joins first and check the audit before you add `WHERE` and `GROUP BY`. With three tables, give each a short name: `order_items AS i`, `products AS p`, `orders AS o`.

## Stretch card

Not required, not checked. `bigquery-public-data.thelook_ecommerce` has `order_items` and `products` tables too. First check that `id` is unique in `products`. Then read the bytes estimate, and calculate revenue (`sale_price`) by product category for order items with `status = 'Complete'`. The public data changes, so there is no fixed answer.

## More practice

**Not checked and not submitted.** Solutions are in the Solved file. Each join question needs its own audit.

- X1 "How many customers who never ordered does each city have?" (as typed)
- X2 "Completed revenue by customer segment." Clean the segment with `LOWER(TRIM(...))`. Audit: which completed order does an `INNER JOIN` to customers lose, and what is it worth?
- X3 "Units sold per category, completed orders."
- X4 "Omar Nasser from Irbid has two customer IDs. What has he spent in total on completed orders?"
- X5 Pagila: films per rating, with the average running time.
- X6 Transfer: in `thelook_ecommerce`, orders per user country. Read the bytes estimate before you run.

## Check yourself: more practice

| Question | Rows returned | One value to check |
|---|---:|---|
| X1 | 9 | Amman 15 |
| X2 | 2 | retail 160,881.50; wholesale 154,204.00 |
| X2a | 1 | order 101664, 938.00 |
| X3 | 6 | Sportswear first, 3,408 units |
| X4 | 2 | C-1401: 18 orders, 6,033.00 |
| X5 | 5 | PG-13: 223 films |

## If something goes wrong

| Problem | Fix |
|---|---|
| `Column name customer_id is ambiguous` | Both tables have that column. Prefix it: `o.customer_id` |
| The audit total grows after a join | You are summing an amount from the "one" side after joining the "many" side. Sum the line amount instead |
| The result has far more rows than expected | Check the `ON` condition: joining on the wrong column pairs rows that do not belong together |
| `Not found: Dataset … pagila` | Upload the three Pagila files first (step 9) |

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026 ([dataset record](../../D04/03-Evr-Upload-Nakheel/Resources/README.md)). Pagila sample database, copyright Devrim Gündüz, [github.com/devrimgunduz/pagila](https://github.com/devrimgunduz/pagila), commit 9baf49c; course copy taken 24 September 2026. See [`Resources/README.md`](Resources/README.md) and the included [`LICENSE.txt`](Resources/LICENSE.txt).
