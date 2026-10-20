# SQL review: following the manager's questions

This walkthrough follows a retail analysis as the questions change. We start by inspecting orders, summarise them at different grains, compare totals, and then investigate order value and delivery speed. Each small SQL change changes either what we see, what one row represents, or what the numbers mean.

Use **GoogleSQL in BigQuery Console**. `D03.orders` is the small table from D01. `nakheel.orders` contains the larger retail dataset, including `channel`, `order_total`, `shipping_fee`, and `delivered_date`. Its orders span September 2024 through August 2026. Amounts are in Jordanian dinars (JOD).

Run one query at a time. Replace dataset names if yours differ. Questions in quotation marks reconstruct the conversation around the queries; they are prompts to think through, rather than a transcript of the class.

## 1. “Show me the completed orders for August.”

Start with individual orders. One output row is one order.

```sql
SELECT order_id, customer_id, order_date, status
FROM D03.orders
WHERE status = 'completed'
  AND order_date >= DATE '2026-08-01'
  AND order_date <= DATE '2026-09-01'
ORDER BY order_date DESC, order_id DESC;
```

**Result:** Four orders, in this order: 1005, 1004, 1003, 1001.

“Can we write the date condition another way?”

Replace the two date conditions with:

```sql
AND order_date BETWEEN DATE '2026-08-01' AND DATE '2026-09-01'
```

Both versions include **1 September**. They produce the same result here because the small dataset has no September orders. A correct-looking result does not prove that the date boundary matches the question.

For August only, use:

```sql
AND order_date >= DATE '2026-08-01'
AND order_date < DATE '2026-09-01'
```

**What changed:** The second boundary now excludes September. `BETWEEN` includes both endpoints.

## 2. “I don't need the customer ID on this screen.”

```sql
SELECT * EXCEPT (customer_id)
FROM D03.orders
WHERE status = 'completed'
  AND order_date >= DATE '2026-08-01'
  AND order_date < DATE '2026-09-01'
ORDER BY order_date DESC, order_id DESC;
```

**Result:** The same four orders, with one fewer column.

**What changed:** The projection: which columns are displayed. **The grain stays one row per order.** Hiding `customer_id` does not combine orders or remove repeated customer accounts.

## 3. “Let's look at Nakheel. How many orders are we dealing with?”

We switch to Nakheel because it has more orders and the order-level amounts needed for the next questions. Start with the whole table, without grouping.

```sql
SELECT
  COUNT(*) AS count_rows,
  COUNT(status) AS non_null_status,
  COUNT(DISTINCT status) AS unique_status,
  AVG(order_total) AS average_order_total
FROM nakheel.orders;
```

| Measure | Result |
|---|---:|
| Rows | 3,000 |
| Non-NULL statuses | 3,000 |
| Different statuses | 3 |
| Average order amount | 113.46 |

The aliases give the results meaningful column names; they do not change the calculations.

“Why do the first two counts match?” Every row has a status. `COUNT(status)` counts non-NULL values, while `COUNT(*)` counts rows.

“Is that average completed sales?” We have included **completed, cancelled, and pending** orders. The number describes all recorded order amounts. It is not yet a completed-sales measure.

## 4. “How does that look by channel and status?”

Add `channel` and `status` to both `SELECT` and `GROUP BY`:

```sql
SELECT
  channel,
  status,
  COUNT(*) AS count_rows,
  COUNT(status) AS non_null_status,
  COUNT(DISTINCT status) AS unique_status,
  AVG(order_total) AS average_order_total
FROM nakheel.orders
GROUP BY channel, status
ORDER BY average_order_total DESC;
```

**Result:** Six rows. One row now represents **one channel and status combination**.

“How come `unique_status` is now 1 on every row?” We grouped by status. Each group already contains a single status value. This count no longer tells us how many statuses exist across the business.

The largest average is **online/pending: 186.86 JOD**, based on only **7 orders**. Compare that with **store/completed: 116.47 JOD**, based on **1,763 orders**. The highest average does not identify the largest source of completed revenue.

## 5. “How many customers are behind those orders?”

Replace the status counts with customer counts:

```sql
SELECT
  channel,
  status,
  COUNT(*) AS count_rows,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(customer_id) AS customer_count,
  AVG(order_total) AS average_order_total
FROM nakheel.orders
GROUP BY channel, status
ORDER BY average_order_total DESC;
```

**What changed:** The grain stays channel × status. We changed the measures.

For **store/completed**, there are **1,763 orders**, **1,763 non-NULL customer IDs**, and **399 different customer accounts**. `COUNT(customer_id)` counts customer ID occurrences on orders; it does not count different customers.

**Think ahead:** A customer can buy through both channels or have orders in several statuses. Adding group-level distinct-customer counts can count the same account more than once.

## 6. “Which group has the most money, rather than the highest average?”

Change `AVG` to `SUM` and sort by the new measure:

```sql
SELECT
  channel,
  status,
  COUNT(*) AS count_rows,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(customer_id) AS customer_count,
  SUM(order_total) AS sum_order_total
FROM nakheel.orders
GROUP BY channel, status
ORDER BY sum_order_total DESC;
```

| Channel | Status | Orders | Different customer accounts | Order amount |
|---|---|---:|---:|---:|
| store | completed | 1,763 | 399 | 205,338.00 |
| online | completed | 1,008 | 298 | 110,685.50 |
| store | cancelled | 128 | 91 | 14,224.00 |
| online | cancelled | 84 | 64 | 7,774.50 |
| online | pending | 7 | 7 | 1,308.00 |
| store | pending | 10 | 9 | 1,040.00 |

**Interpretation:** Store/completed is the largest group by total order amount. Online/pending had the highest average because its small group contained relatively large orders.

The two completed rows sum to **316,023.50 JOD**. Cancelled and pending amounts describe recorded orders; do not label those amounts completed revenue.

## 7. “What about the orders that weren't completed?”

Keep the previous query and insert this before `GROUP BY`:

```sql
WHERE status != 'completed'
```

**Result:** Four channel × status rows remain: the two cancelled groups and the two pending groups. Together they contain **229 orders** worth **24,346.50 JOD**.

**What changed:** The population being analysed. We are now discussing non-completed orders across the full dataset period, rather than August alone.

For this data, the remaining statuses are cancelled and pending. If `status` were NULL, `status != 'completed'` would not retain that row. To include missing statuses deliberately, use `status != 'completed' OR status IS NULL`.

“Can we ignore the channel and just look at status?”

```sql
SELECT
  status,
  COUNT(*) AS count_rows,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(customer_id) AS customer_count,
  SUM(order_total) AS sum_order_total
FROM nakheel.orders
WHERE status != 'completed'
GROUP BY status
ORDER BY sum_order_total DESC;
```

| Status | Orders | Different customer accounts | Order amount |
|---|---:|---:|---:|
| cancelled | 212 | 130 | 21,998.50 |
| pending | 17 | 16 | 2,348.00 |

**What changed:** Removing channel from `SELECT` **and** `GROUP BY` changes the grain to one row per status.

“Why aren't cancelled customers 91 + 64 = 155?” There are **130 distinct accounts** with cancelled orders. Some accounts appear in both channels, so their separate distinct counts overlap. Recalculate the distinct count at the grain you need.

## 8. “Put the channel details and the status totals together.”

Name the two analyses so we can refer to them:

```sql
WITH status_channel_grain AS (
  SELECT
    channel,
    status,
    COUNT(*) AS count_rows,
    SUM(order_total) AS sum_order_total
  FROM nakheel.orders
  WHERE status != 'completed'
  GROUP BY channel, status
),
status_grain AS (
  SELECT
    status,
    COUNT(*) AS count_rows,
    SUM(order_total) AS sum_order_total
  FROM nakheel.orders
  WHERE status != 'completed'
  GROUP BY status
)
SELECT * EXCEPT (channel)
FROM status_channel_grain
UNION ALL
SELECT *
FROM status_grain;
```

**Result:** Six rows, but the rows mean different things. Four are channel-level groups; two are status totals. Removing the channel column hides the difference without changing the calculations.

**Why this is misleading:** Summing the amount column gives **48,693.00 JOD**, twice the actual non-completed amount. Every order is represented in a detail group and again in its status total. `UNION ALL` stacks rows; it does not attach a total to its details.

This is not a syntax failure. The output has lost the labels needed to interpret it. A stacked subtotal report can be valid when you retain the channel and explicitly label each aggregation level. For a total beside each detail row, use a join or a window.

## 9. “I meant: show each channel beside its status total.”

Keep the same two CTEs from section 8. Replace the final `SELECT ... UNION ALL ...` with:

```sql
SELECT
  scg.*,
  sg.sum_order_total AS status_total
FROM status_channel_grain AS scg
INNER JOIN status_grain AS sg
  ON scg.status = sg.status
ORDER BY scg.status, scg.channel;
```

| Status | Channel | Orders | Channel amount | Status total |
|---|---|---:|---:|---:|
| cancelled | online | 84 | 7,774.50 | 21,998.50 |
| cancelled | store | 128 | 14,224.00 | 21,998.50 |
| pending | online | 7 | 1,308.00 | 2,348.00 |
| pending | store | 10 | 1,040.00 | 2,348.00 |

**What changed:** The join adds a column while keeping channel × status grain. It matches each detail group to exactly one status-total row.

**Check:** The status total repeats for each channel. It is a comparison value. Summing that repeated column would double-count the totals again.

## 10. “Can we get those totals from the grouped result itself?”

Use one CTE and calculate windows over its four rows:

```sql
WITH status_channel_grain AS (
  SELECT
    channel,
    status,
    COUNT(*) AS count_rows,
    SUM(order_total) AS sum_order_total
  FROM nakheel.orders
  WHERE status != 'completed'
  GROUP BY channel, status
)
SELECT
  *,
  SUM(sum_order_total) OVER () AS grand_total,
  SUM(sum_order_total) OVER (PARTITION BY status) AS status_total
FROM status_channel_grain
ORDER BY status, channel;
```

**Result:** The same four detail groups. `grand_total` is **24,346.50** on every row. `status_total` is **21,998.50** for cancelled rows and **2,348.00** for pending rows.

The inner `SUM(order_total)` calculates each group's amount from orders. The outer `SUM(sum_order_total) OVER (...)` adds those group amounts while preserving the detail rows.

**The denominator has a scope:** This grand total means **all non-completed order amounts**, because that is the population admitted into the CTE. It does not include completed orders.

## 11. “Hide the tiny groups. Keep only groups with more than 20 orders.”

One suggestion is to add this to the outer query in section 10, before its final `ORDER BY`:

```sql
WHERE count_rows > 20
```

**Result:** Only the two cancelled groups remain. The displayed grand total becomes **21,998.50**.

“How come the grand total changed? I only wanted to hide two rows.”

`WHERE` removes the pending groups **before** the windows are evaluated. The windows now see only the cancelled groups.

Another suggestion is to put `HAVING COUNT(*) > 20` inside the CTE, after its `GROUP BY`. In this example, that has the same effect on the window input: it removes those groups before the outer windows run.

Both approaches are valid if the question is **“What is the total of the retained groups?”** For **“Hide small groups, but keep totals for the original population,”** filter after calculating the windows:

```sql
WITH status_channel_grain AS (
  SELECT
    channel,
    status,
    COUNT(*) AS count_rows,
    SUM(order_total) AS sum_order_total
  FROM nakheel.orders
  WHERE status != 'completed'
  GROUP BY channel, status
),
with_totals AS (
  SELECT
    *,
    SUM(sum_order_total) OVER () AS grand_total,
    SUM(sum_order_total) OVER (PARTITION BY status) AS status_total
  FROM status_channel_grain
)
SELECT *
FROM with_totals
WHERE count_rows > 20
ORDER BY status, channel;
```

**Result:** Two visible cancelled rows, but `grand_total` remains **24,346.50**. The hidden pending groups still contribute to that denominator.

**Alternative in BigQuery:** In section 10's query, use `QUALIFY count_rows > 20` instead of outer `WHERE`. Because that query contains window functions, `QUALIFY` filters after those calculations and preserves their original totals.

## 12. “What if we describe orders as High, Medium, and Standard?”

Return to individual orders before summarising. `CASE` adds a label without changing the row count.

```sql
WITH analysis AS (
  SELECT
    order_id,
    CASE
      WHEN order_total >= 150 THEN 'High'
      WHEN order_total >= 100 THEN 'Medium'
      ELSE 'Standard'
    END AS value_band,
    customer_id,
    status,
    order_total,
    shipping_fee,
    delivered_date,
    order_date
  FROM nakheel.orders
)
SELECT *
FROM analysis
ORDER BY order_id;
```

**Result:** 3,000 order rows, each with a value band. High means at least 150 JOD; Medium means at least 100 and below 150; Standard means below 100 in this dataset, where amounts are never NULL.

**Think:** What happens if `>= 100` comes first? A 200 JOD order matches it and becomes Medium. `CASE` uses the first matching condition. In another dataset, handle a NULL amount explicitly so it is not silently labelled Standard.

“Which band contributes the most completed sales?”

Keep that CTE and replace its final `SELECT` with:

```sql
SELECT
  value_band,
  SUM(order_total) AS completed_order_amount,
  AVG(order_total) AS average_order_amount,
  COUNT(*) AS number_of_orders
FROM analysis
WHERE status = 'completed'
GROUP BY value_band
ORDER BY completed_order_amount DESC;
```

| Band | Completed orders | Amount | Average amount |
|---|---:|---:|---:|
| High | 476 | 182,640.50 | 383.70 |
| Standard | 1,936 | 90,251.50 | 46.62 |
| Medium | 359 | 43,131.50 | 120.14 |

High-value orders contribute the most amount, while Standard orders are the most numerous. These are different ways of describing the same business.

**Naming matters:** `SUM(order_total)` is an amount. An alias such as `total_orders` could be mistaken for an order count. `COUNT(order_total)` matches `COUNT(*)` here because no amount is NULL; in other data, it counts only orders with a recorded amount.

## 13. “Do higher-value orders take longer to arrive?”

First inspect a few individual rows and calculate a duration:

```sql
SELECT
  order_id,
  order_date,
  delivered_date,
  DATE_DIFF(order_date, delivered_date, DAY) AS days_between
FROM nakheel.orders
WHERE status = 'completed'
ORDER BY order_id
LIMIT 20;
```

**Wrong turn:** Deliveries after the order date produce negative durations. `DATE_DIFF(end_date, start_date, DAY)` subtracts the second date from the first.

Change the expression to:

```sql
DATE_DIFF(delivered_date, order_date, DAY) AS days_between
```

Now add that expression to the `analysis` CTE from section 12, after `order_date`. Replace the final query with:

```sql
SELECT
  value_band,
  COUNT(*) AS delivered_orders,
  SUM(order_total) AS completed_order_amount,
  AVG(order_total) AS average_order_amount,
  ROUND(AVG(days_between), 2) AS average_days_between,
  MAX(days_between) AS longest_delivery,
  MIN(days_between) AS fastest_delivery
FROM analysis
WHERE status = 'completed'
  AND delivered_date IS NOT NULL
GROUP BY value_band
ORDER BY average_days_between DESC;
```

**Result:** Average days are Standard **0.93**, Medium **0.91**, High **0.84**. Every band's minimum is 0 and maximum is 4.

**Why specify the population?** Without the status filter, order counts and amounts include cancelled and pending orders, while `AVG(days_between)` ignores their missing durations. The measures would describe different populations in the same row.

**Interpret carefully:** These averages also combine store and online orders. They do not establish that order value causes a delivery-speed difference. We will check the channel next.

## 14. “Can we give delivery speed readable labels?”

The first version in class used:

```sql
CASE
  WHEN DATE_DIFF(delivered_date, order_date, DAY) = 0 THEN 'SAME DAY'
  WHEN DATE_DIFF(delivered_date, order_date, DAY) = 1 THEN 'NEXT DAY'
  ELSE 'LONGER DELIVERY'
END AS speed_type
```

“What happens when the order hasn't been delivered?”

A missing delivery date produces a NULL duration. Neither comparison matches, so the row falls into `ELSE`. This labels **229 undated orders** as longer deliveries, even though no delivery duration is known.

Use explicit missing-date handling. We can save the corrected order-level analysis as a view for the sales department. The following statement creates or replaces the named view in your practice dataset:

```sql
CREATE OR REPLACE VIEW nakheel.vw_insights_sales_department AS
SELECT
  order_id,
  customer_id,
  channel,
  status,
  order_total,
  shipping_fee,
  order_date,
  delivered_date,
  CASE
    WHEN order_total IS NULL THEN 'Unknown'
    WHEN order_total >= 150 THEN 'High'
    WHEN order_total >= 100 THEN 'Medium'
    ELSE 'Standard'
  END AS value_band,
  DATE_DIFF(delivered_date, order_date, DAY) AS days_between,
  CASE
    WHEN delivered_date IS NULL THEN 'NO DELIVERY DATE'
    WHEN DATE_DIFF(delivered_date, order_date, DAY) < 0 THEN 'CHECK DATES'
    WHEN DATE_DIFF(delivered_date, order_date, DAY) = 0 THEN 'SAME DAY'
    WHEN DATE_DIFF(delivered_date, order_date, DAY) = 1 THEN 'NEXT DAY'
    ELSE 'LONGER DELIVERY'
  END AS speed_type
FROM nakheel.orders;
```

**Grain:** One row per order, still 3,000 rows. The extra channel column lets us investigate the mix of store and online orders later. There are no negative durations in the course data; the `CHECK DATES` label makes such a problem visible if one appears.

A CTE names a result for one statement. A logical view saves the query definition for later statements. Neither requires you to manually copy its result rows into a new table.

If you cannot create a view, use the view's `SELECT` as a CTE named `sales_analysis` and query that CTE instead of the view in the examples below.

## 15. “What percentage of orders falls into each speed group?”

First group and count. Then put the total beside those groups and calculate their shares:

```sql
WITH analysis_1 AS (
  SELECT speed_type, COUNT(*) AS number_of_orders
  FROM nakheel.vw_insights_sales_department
  GROUP BY speed_type
)
SELECT
  speed_type,
  number_of_orders,
  SUM(number_of_orders) OVER () AS grand_total,
  ROUND(
    100.0 * number_of_orders / SUM(number_of_orders) OVER (),
    2
  ) AS order_share_pct
FROM analysis_1
ORDER BY number_of_orders DESC;
```

| Speed group | Orders | Share of all orders |
|---|---:|---:|
| SAME DAY | 1,763 | 58.77% |
| LONGER DELIVERY | 754 | 25.13% |
| NEXT DAY | 254 | 8.47% |
| NO DELIVERY DATE | 229 | 7.63% |

**Denominator:** All **3,000** orders, including cancelled and pending orders.

“Actually, I meant the percentage of completed orders.”

Add `WHERE status = 'completed'` **inside the CTE**, before `GROUP BY`. The denominator becomes **2,771**, and the three observed speed shares become Same day **63.62%**, Longer delivery **27.21%**, Next day **9.17%**.

This is the same denominator question from section 11, now applied to a percentage. Name the population before interpreting a percentage.

## 16. “Are we charging more for faster delivery?”

Add shipping and amount measures to the grouped step:

```sql
WITH analysis_1 AS (
  SELECT
    speed_type,
    COUNT(*) AS number_of_orders,
    ROUND(AVG(shipping_fee), 2) AS average_shipping_fee,
    SUM(order_total + shipping_fee) AS amount_including_shipping
  FROM nakheel.vw_insights_sales_department
  WHERE status = 'completed'
  GROUP BY speed_type
)
SELECT
  *,
  SUM(number_of_orders) OVER () AS grand_total,
  ROUND(
    100.0 * number_of_orders / SUM(number_of_orders) OVER (),
    2
  ) AS order_share_pct
FROM analysis_1
ORDER BY number_of_orders DESC;
```

**What changed:** The grain stays one row per speed group. We added average shipping fee and an amount including shipping. The percentage still measures **order share**, not revenue share. A revenue share would need an amount in both numerator and denominator.

“Same-day orders have zero average shipping. Does that mean faster shipping is free?”

Check the channel instead of assuming the label describes a shipping service:

```sql
SELECT
  channel,
  speed_type,
  COUNT(*) AS number_of_orders,
  ROUND(AVG(shipping_fee), 2) AS average_shipping_fee
FROM nakheel.vw_insights_sales_department
WHERE status = 'completed'
GROUP BY channel, speed_type
ORDER BY channel, speed_type;
```

**Finding:** All **1,763** same-day completed orders are store orders. The online orders are next-day or longer. The dataset also charges zero shipping on online orders of at least 50 JOD. Channel and order value affect the fee, so the grouped averages alone do not show a causal effect of delivery speed.

**Amount check:** Completed goods total **316,023.50 JOD**. Shipping adds **1,032.50 JOD**, giving **317,056.00 JOD** including shipping. In a dataset with missing amounts or fees, check how NULLs should be treated before adding the two fields.

## 17. “What if an order date started a two-month trial?”

This is a **hypothetical use of the dates** to practise date arithmetic. The retail dataset does not record an actual trial or subscription.

```sql
SELECT
  order_id,
  order_date AS trial_date,
  DATE_ADD(order_date, INTERVAL 2 MONTH) AS expire_date,
  DATE_DIFF(
    DATE_ADD(order_date, INTERVAL 2 MONTH),
    CURRENT_DATE('Asia/Amman'),
    DAY
  ) AS days_until
FROM nakheel.orders
ORDER BY order_date DESC, order_id DESC;
```

`DATE_ADD` moves the date forward. `DATE_SUB(order_date, INTERVAL 2 WEEK)` would move it back two weeks. Two calendar months is different from a fixed 60 days; month-end dates are adjusted when the target month is shorter.

**Interpret `days_until`:** Positive means expiry is in the future; zero means expiry is today; negative means expiry is in the past. The result changes with the current date. The explicit time zone uses the date in Amman.

“Show only trials that have time remaining.”

Rather than repeat the expression several times, name the steps:

```sql
WITH trial_dates AS (
  SELECT
    order_id,
    order_date AS trial_date,
    DATE_ADD(order_date, INTERVAL 2 MONTH) AS expire_date
  FROM nakheel.orders
),
with_remaining AS (
  SELECT
    *,
    DATE_DIFF(expire_date, CURRENT_DATE('Asia/Amman'), DAY) AS days_until
  FROM trial_dates
)
SELECT *
FROM with_remaining
WHERE days_until > 0
ORDER BY expire_date, order_id;
```

**Repeatable check:** Replace `CURRENT_DATE('Asia/Amman')` with `DATE '2026-10-20'`. There are **58** orders with hypothetical expiry dates after that date. With the `> 0` rule, an expiry date equal to the reference date is excluded. Whether expiry day itself is allowed is a business rule to agree before choosing `>` or `>=`.

## Follow the changes in meaning

| Change in SQL | Change in the analysis |
|---|---|
| `SELECT * EXCEPT (...)` | Hide a column; preserve the existing row grain |
| `WHERE status != 'completed'` | Change the population being analysed |
| Add channel to `GROUP BY` | Split each status into channel-level groups |
| Remove channel from `GROUP BY` | Recalculate measures at status grain |
| Change `AVG` to `SUM` | Move from typical order size to total amount |
| `COUNT(customer_id)` → `COUNT(DISTINCT customer_id)` | Count different accounts instead of ID occurrences |
| `UNION ALL` | Stack result rows; keep their individual meanings visible |
| Join details to a status total | Attach a comparison value that repeats across detail rows |
| `SUM(...) OVER ()` | Calculate a total without collapsing the input rows |
| `PARTITION BY status` | Calculate a separate window total for each status |
| Filter before the windows | Recalculate totals using the retained groups |
| Filter after the windows | Hide rows while keeping already-calculated totals |
| Add `CASE` at order grain | Add a label without aggregating the orders |
| Group by the new label | Summarise orders using that classification |
| Swap arguments in `DATE_DIFF` | Reverse the sign of the duration |
| Handle NULL before `ELSE` | Keep unknown delivery duration separate from slow delivery |

For each result, ask: **What does one row represent? Which orders contributed? What does each measure count or sum? What is the denominator?** Those questions explain why a small, valid SQL edit can produce a different business answer.

### References

The expected values come from the ASAC course CSV files. BigQuery syntax: [Query syntax](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax), [window functions](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/window-function-calls), [date functions](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/date_functions), and [conditional expressions](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/conditional_expressions).
