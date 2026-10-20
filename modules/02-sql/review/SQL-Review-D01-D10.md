# SQL review: D01–D10

We will use the small retail tables from D01 to connect the SQL concepts covered so far. Our main question is: **Which product category generated the most revenue from completed orders in August 2026?** We will then use Nakheel for examples that benefit from more data.

## Before you start

Use **GoogleSQL in BigQuery Console**. These examples use the course dataset names:

- `D03`: the four small CSV files introduced on D01 and uploaded on D03.
- `nakheel`: the larger retail dataset in `shared/datasets/nakheel/`.

Run one query at a time. Each query is independent unless the instructions say to modify the previous query. If your dataset has a different name, replace `D03` or `nakheel`. If your tables are in another project, use a full reference such as `` `your-project.D03.orders` ``.

| Small table | One row represents | Key | Rows |
|---|---|---|---:|
| `D03.customers` | A customer account | `customer_id` | 5 |
| `D03.orders` | An order | `order_id` | 5 |
| `D03.order_items` | A line on an order | `item_id` | 12 |
| `D03.products` | A product | `product_id` | 5 |

An order can contain several lines. **The small `orders` table has no `order_total` column.** Calculate value from `order_items.qty * order_items.price`. Nakheel's `orders` table does have `order_total`.

For this review, revenue means the value of goods on **completed** orders, excluding shipping. Before running a query, predict what one output row represents and how many rows you expect.

## 1. Select columns, sort, and limit — D03

**Concept:** `SELECT` chooses columns. `ORDER BY` sorts the result. `LIMIT` restricts how many result rows are returned.

```sql
SELECT order_id, customer_id, order_date, status
FROM D03.orders
ORDER BY order_date DESC, order_id DESC
LIMIT 3;
```

**Expected:** Orders `1005`, `1004`, and `1003`, in that order.

**Try:** Remove `LIMIT 3`. You should get all five orders. Without `ORDER BY`, you cannot rely on the order in which rows appear.

## 2. Filter rows — D03

**Concept:** `WHERE` keeps rows that satisfy a condition. Use `AND` when both conditions must hold. Use parentheses when combining `AND` and `OR`.

```sql
SELECT order_id, customer_id, order_date, status
FROM D03.orders
WHERE status = 'completed'
  AND order_date >= DATE '2026-08-01'
  AND order_date < DATE '2026-09-01'
ORDER BY order_id;
```

**Expected:** Four orders: `1001`, `1003`, `1004`, `1005`. Order `1002` is cancelled.

**Try:** Add `AND customer_id IN ('C-118', 'C-204')`. You should get three orders.

The date range includes August and excludes September. Fixed dates make the example repeatable whenever you run it.

## 3. Count at the correct grain — D01, D03–D04

**Concept:** `COUNT(*)` counts rows. `COUNT(DISTINCT column)` counts different non-NULL values. The table's grain determines what a row count means.

```sql
SELECT
  COUNT(*) AS line_count,
  COUNT(DISTINCT order_id) AS order_count,
  SUM(qty) AS unit_count
FROM D03.order_items;
```

**Expected:** `12` lines, `5` orders, `23` units. This includes the cancelled order because we have not filtered by status.

**Check:** Why is `COUNT(*)` not the number of orders here? An order can appear on several lines. Also, 12 lines does not mean 12 different products.

## 4. Clean text and handle missing values — D04–D05

**Concept:** `TRIM` removes surrounding spaces, `UPPER` standardises case, and `COALESCE` supplies a value when an expression is NULL. `NULLIF(x, '')` turns an empty string into NULL.

```sql
SELECT
  customer_id,
  customer_name,
  segment,
  UPPER(TRIM(segment)) AS clean_segment,
  COALESCE(NULLIF(TRIM(city), ''), 'Unknown') AS clean_city
FROM D03.customers
ORDER BY customer_id;
```

**Expected:** The three versions of Retail become `RETAIL`. C-455's city becomes `Unknown`.

To find missing cities, use:

```sql
SELECT customer_id, customer_name
FROM D03.customers
WHERE NULLIF(TRIM(city), '') IS NULL;
```

**Expected:** `C-455`, Sami Odeh. Use `IS NULL`; `= NULL` does not test for missing values.

**Check:** Omar Nasser appears under two account IDs. A shared name alone is not enough evidence to merge accounts in an unfamiliar dataset.

## 5. Group rows and filter groups — D04–D05

**Concept:** `GROUP BY` produces one row per group. `WHERE` filters input rows; `HAVING` filters the groups after aggregation.

```sql
SELECT customer_id, COUNT(*) AS completed_orders
FROM D03.orders
WHERE status = 'completed'
GROUP BY customer_id
HAVING COUNT(*) >= 2
ORDER BY completed_orders DESC, customer_id;
```

**Expected:** One row: `C-204`, with `2` completed orders.

**Try:** Remove `HAVING`. You should get three customer accounts: C-204 has two completed orders; C-118 and C-401 have one each.

## 6. Calculate a measure — D04–D05

**Concept:** Calculate line value before summing it. `price` is the price of one unit.

```sql
SELECT
  order_id,
  SUM(qty * price) AS order_value
FROM D03.order_items
GROUP BY order_id
ORDER BY order_id;
```

**Expected:**

| Order | Value (JOD) |
|---|---:|
| 1001 | 47.00 |
| 1002 | 100.50 |
| 1003 | 61.50 |
| 1004 | 162.00 |
| 1005 | 116.00 |

**Check:** Why would `SUM(price)` give the wrong result? It ignores quantity. These values still include the cancelled order because `order_items` does not contain status.

## 7. Join tables to answer the business question — D06–D07

**Concept:** Join items to orders for status and to products for category. Match the keys with `ON`. Then filter, group, and sum.

```sql
SELECT
  p.category,
  SUM(i.qty * i.price) AS revenue
FROM D03.order_items AS i
INNER JOIN D03.orders AS o
  ON i.order_id = o.order_id
INNER JOIN D03.products AS p
  ON i.product_id = p.product_id
WHERE o.status = 'completed'
  AND o.order_date >= DATE '2026-08-01'
  AND o.order_date < DATE '2026-09-01'
GROUP BY p.category
ORDER BY revenue DESC, p.category;
```

**Expected:**

| Category | Revenue (JOD) |
|---|---:|
| Accessories | 166.00 |
| Shoes | 136.50 |
| Outerwear | 84.00 |

Total completed revenue is **386.50 JOD**.

**Try:** Remove only `o.status = 'completed'` and its following `AND`. Shoes becomes the winner at `195.00`; Accessories remains `166.00`; Outerwear becomes `126.00`. The SQL runs successfully, but it answers a different question.

**Check:** Before grouping, each item should match one order and one product. Adding these two joins should preserve all 12 item rows. A join that unexpectedly increases the row count needs investigation.

## 8. Keep customers with no completed orders — D06–D07

**Concept:** `LEFT JOIN` keeps every customer. Put the status condition in `ON` so customers without completed orders remain in the result. Count the matched order IDs.

```sql
SELECT
  c.customer_id,
  c.customer_name,
  COUNT(o.order_id) AS completed_orders
FROM D03.customers AS c
LEFT JOIN D03.orders AS o
  ON c.customer_id = o.customer_id
  AND o.status = 'completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY c.customer_id;
```

**Expected:** All five accounts. Counts by customer ID: C-118 → `1`, C-204 → `2`, C-377 → `0`, C-401 → `1`, C-455 → `0`.

**Check:** `COUNT(*)` would count the retained row even when there is no order, producing `1` for the two non-buyers. `COUNT(o.order_id)` ignores their NULL order IDs.

**Try:** To return only customers with zero completed orders, add `HAVING COUNT(o.order_id) = 0` after `GROUP BY`. You should get C-377 and C-455. Moving the status filter to `WHERE` would remove those customers before counting.

## 9. Use CASE to label results — D05, D07

**Concept:** `CASE` creates a value based on conditions. Conditions are checked in order; the first match wins.

```sql
SELECT
  order_id,
  SUM(qty * price) AS order_value,
  CASE
    WHEN SUM(qty * price) >= 150 THEN 'High'
    WHEN SUM(qty * price) >= 100 THEN 'Medium'
    ELSE 'Standard'
  END AS value_band
FROM D03.order_items
GROUP BY order_id
ORDER BY order_id;
```

**Expected:** 1001 Standard, 1002 Medium, 1003 Standard, 1004 High, 1005 Medium. This example labels all five orders, including the cancelled one.

**Check:** What happens to order 1004 if the `>= 100` condition comes first? It becomes Medium because that condition already matches.

## 10. Use a subquery — D08–D09

**Question:** Which customer accounts have at least one completed order?

**Concept:** The inner query supplies a set of customer IDs. The outer query tests membership using `IN`.

```sql
SELECT customer_id, customer_name
FROM D03.customers
WHERE customer_id IN (
  SELECT customer_id
  FROM D03.orders
  WHERE status = 'completed'
)
ORDER BY customer_id;
```

**Expected:** C-118, C-204, C-401. Repeated IDs inside the subquery do not duplicate the outer customer rows.

**Check:** A join may produce several rows per customer when they have several orders. Here, the question asks whether a match exists.

## 11. Use a CTE to name a step — D08–D09

**Question:** Which completed orders are worth more than the average completed order?

**Concept:** `WITH` names an intermediate query result. Here we calculate one row per completed order, then compare those order totals with their average using a scalar subquery.

```sql
WITH completed_order_totals AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    SUM(i.qty * i.price) AS order_value
  FROM D03.orders AS o
  INNER JOIN D03.order_items AS i
    ON o.order_id = i.order_id
  WHERE o.status = 'completed'
  GROUP BY o.order_id, o.customer_id, o.order_date
)
SELECT order_id, order_value
FROM completed_order_totals
WHERE order_value > (
  SELECT AVG(order_value)
  FROM completed_order_totals
)
ORDER BY order_value DESC, order_id;
```

**Expected:** 1004 → `162.00`, 1005 → `116.00`. The average completed order is `96.625` JOD.

**Check:** Average order value is calculated from order totals. Averaging item lines answers a different question. A CTE exists within this statement; it does not create a saved table.

## 12. Add a window calculation without collapsing rows — D10

**Concept:** A regular aggregate collapses rows. `OVER ()` calculates across all input rows and places the result beside each row.

Keep the **same CTE from example 11** and replace everything after its closing `)` with:

```sql
SELECT
  order_id,
  order_value,
  AVG(order_value) OVER () AS average_order_value,
  SUM(order_value) OVER () AS total_revenue
FROM completed_order_totals
ORDER BY order_id;
```

**Expected:** Four rows. Each has average `96.625` and total `386.50` beside its own order value.

**Try:** Add `QUALIFY order_value > AVG(order_value) OVER ()` before `ORDER BY`. You get the same two above-average orders as example 11.

**Check:** `WHERE` filters before windows are calculated; `QUALIFY` filters after window calculations.

## 13. Select the latest order per customer — D10

**Concept:** `PARTITION BY` creates a separate window for each customer. `ROW_NUMBER` numbers that customer's orders. `QUALIFY` keeps the first one.

```sql
SELECT customer_id, order_id, order_date
FROM D03.orders
WHERE status = 'completed'
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY customer_id
  ORDER BY order_date DESC, order_id DESC
) = 1
ORDER BY customer_id;
```

**Expected:** C-118 → 1005, C-204 → 1003, C-401 → 1004.

**Check:** `LIMIT 1` would keep one order overall. This query keeps one per customer. The order ID breaks ties when dates match.

## 14. Calculate a running total and compare with the previous row — D10

Keep the **same CTE from example 11** and replace everything after its closing `)` with:

```sql
SELECT
  order_id,
  order_date,
  order_value,
  SUM(order_value) OVER (
    ORDER BY order_date, order_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_revenue,
  LAG(order_value) OVER (
    ORDER BY order_date, order_id
  ) AS previous_order_value
FROM completed_order_totals
ORDER BY order_date, order_id;
```

**Expected:**

| Order | Order value | Running revenue | Previous order value |
|---|---:|---:|---:|
| 1001 | 47.00 | 47.00 | NULL |
| 1003 | 61.50 | 108.50 | 47.00 |
| 1004 | 162.00 | 270.50 | 61.50 |
| 1005 | 116.00 | 386.50 | 162.00 |

The frame starts at the first row and ends at the current row. `LAG` reads the preceding row in the window order. This compares consecutive completed orders across the whole dataset; adding `PARTITION BY customer_id` would restart the calculations for each customer.

## Optional: practise more patterns

### A. Stack rows with UNION — D07

**Concept:** `UNION ALL` stacks results and keeps repeats. `UNION DISTINCT` removes duplicate result rows. Both sides need the same number of columns with compatible types.

```sql
SELECT customer_id
FROM D03.customers
WHERE city = 'Amman'
UNION ALL
SELECT customer_id
FROM D03.orders
WHERE status = 'completed';
```

**Expected:** Six rows. Change `UNION ALL` to `UNION DISTINCT`: four IDs remain, C-118, C-204, C-377, C-401. Add `ORDER BY customer_id` at the end to sort the combined result. In BigQuery, write `ALL` or `DISTINCT` explicitly after `UNION`.

### B. Compare ranking functions — D10

**Concept:** `ROW_NUMBER` assigns a different number to each row. `RANK` gives ties the same rank and leaves a gap afterwards. `DENSE_RANK` gives ties the same rank without gaps.

```sql
WITH customer_counts AS (
  SELECT c.customer_id, COUNT(o.order_id) AS completed_orders
  FROM D03.customers AS c
  LEFT JOIN D03.orders AS o
    ON c.customer_id = o.customer_id
    AND o.status = 'completed'
  GROUP BY c.customer_id
)
SELECT
  customer_id,
  completed_orders,
  ROW_NUMBER() OVER (
    ORDER BY completed_orders DESC, customer_id
  ) AS row_num,
  RANK() OVER (ORDER BY completed_orders DESC) AS rank_num,
  DENSE_RANK() OVER (ORDER BY completed_orders DESC) AS dense_rank_num
FROM customer_counts
ORDER BY completed_orders DESC, customer_id;
```

**Expected:** Order counts `2, 1, 1, 0, 0`; ranks `1, 2, 2, 4, 4`; dense ranks `1, 2, 2, 3, 3`. The ranking windows omit customer ID so equal order counts remain tied.

### C. Nakheel: avoid summing repeated order totals — D06–D07

**Concept:** Joining orders to their item lines repeats the order-level values. Summing those repeated values inflates the answer.

```sql
SELECT
  COUNT(*) AS joined_rows,
  COUNT(DISTINCT o.order_id) AS completed_orders,
  SUM(o.order_total) AS repeated_order_total,
  SUM(i.qty * i.price) AS line_revenue
FROM nakheel.orders AS o
INNER JOIN nakheel.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed';
```

**Observe:** The joined row count exceeds the order count. `repeated_order_total` is inflated because orders with multiple lines contribute their total several times.

For total completed-order revenue, use the table where each order appears once:

```sql
SELECT
  COUNT(*) AS completed_orders,
  SUM(order_total) AS revenue
FROM nakheel.orders
WHERE status = 'completed';
```

**Expected:** `2,771` completed orders and revenue of `316,023.50` JOD.

**Check:** `SUM(DISTINCT order_total)` is not a general fix. Different orders can have the same value, and both orders must count.

### D. Nakheel: monthly trends — D04, D09–D10

**Concept:** `DATE_TRUNC` groups dates into months. Calculate monthly revenue first, then apply windows to those monthly rows.

```sql
WITH monthly AS (
  SELECT
    DATE_TRUNC(order_date, MONTH) AS revenue_month,
    SUM(order_total) AS revenue
  FROM nakheel.orders
  WHERE status = 'completed'
  GROUP BY revenue_month
)
SELECT
  revenue_month,
  revenue,
  LAG(revenue) OVER (ORDER BY revenue_month) AS previous_month_revenue,
  AVG(revenue) OVER (
    ORDER BY revenue_month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_average
FROM monthly
ORDER BY revenue_month;
```

**Expected:** 24 months, September 2024 through August 2026. April 2026 revenue is `20,237.00` and its three-month moving average is `16,016.00`.

**Check:** The moving average uses the current row and up to two previous rows. The first month has only one row available. These are three calendar months here because the dataset has a row for every month; a missing month would require filling the gap first.

### E. A saved view — D08–D09

**Concept:** A logical view saves a query so you can refer to its result by name. Unlike a CTE, it remains available for later statements. It does not store a separate copy of the result rows.

If you have permission to create views in `D03`, run this once. It creates a new view called `review_completed_order_totals`:

```sql
CREATE VIEW D03.review_completed_order_totals AS
SELECT
  o.order_id,
  o.customer_id,
  o.order_date,
  SUM(i.qty * i.price) AS order_value
FROM D03.orders AS o
INNER JOIN D03.order_items AS i
  ON o.order_id = i.order_id
WHERE o.status = 'completed'
GROUP BY o.order_id, o.customer_id, o.order_date;
```

Then query it:

```sql
SELECT *
FROM D03.review_completed_order_totals
ORDER BY order_id;
```

**Expected:** The same four completed-order totals from example 11. If the view already exists, query it directly rather than running `CREATE VIEW` again.

## Choose the clause that matches the task

| Task | SQL |
|---|---|
| Keep individual rows | `WHERE` |
| Combine related tables | `JOIN ... ON` |
| Produce one result row per group | `GROUP BY` |
| Keep groups based on an aggregate | `HAVING` |
| Label rows using rules | `CASE` |
| Use a query inside another query | Subquery |
| Name intermediate steps in one statement | `WITH` / CTE |
| Calculate across rows while keeping the detail | Window function with `OVER` |
| Keep rows based on a window result | `QUALIFY` |
| Stack compatible query results | `UNION ALL` / `UNION DISTINCT` |
| Reuse a saved query across statements | View |

For the queries here, a useful logical order is **FROM/JOIN → WHERE → GROUP BY/aggregation → HAVING → window calculations → QUALIFY → DISTINCT → ORDER BY → LIMIT**. This explains why the three filtering clauses serve different purposes. It describes query meaning, not the physical execution plan.

## Final practice

Using the small tables, write a query that returns **all five customer accounts**, their completed-order count, and their completed revenue. Show zero for accounts with no completed orders.

**Hint:** Build one row per completed order first. Then left join those results to customers. Use `COUNT(order_id)` and `COALESCE(SUM(order_value), 0)`.

**Check your result:** C-118 → 1 order, 116.00; C-204 → 2 orders, 108.50; C-377 → 0, 0.00; C-401 → 1, 162.00; C-455 → 0, 0.00. Revenue must total **386.50 JOD**.

## References

- Course materials: [ASAC Data Science](https://github.com/tatwan/ASAC_Data_Science), SQL module and the D01/Nakheel dataset files.
- BigQuery: [Query syntax](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax) and [Window function calls](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/window-function-calls).
