# Lab: A KPI set for Nakheel Retail

In this lab, you will define and calculate five KPIs for Nakheel's managers, then show how the answer to "is the typical order getting bigger?" changes with the grain you choose.

**Time:** 45 minutes, TA-led · **Data:** `nakheel.orders` · **Starter:** `Unsolved/kpi_set.sql`

**Before you start:** the four `nakheel` tables are uploaded (3,000 rows in `orders`). If not, use the CSVs and steps in the [Nakheel upload activity](../03-Evr-Upload-Nakheel/README.md); `orders.csv` alone is enough for C1 to C3.

**What you hand in:** nothing. Save your `.sql` file with the definition table and every comment block filled in. It is one of the files you choose from for Assignment 1, which is issued on D09 (Sunday 11 October).

## The five KPIs

Fill in the definition table at the top of the starter file before you write any query. For each KPI: the rule in words, and the grain (what one row of the result is).

| # | KPI | What the manager asked for |
|---|---|---|
| 1 | Completed revenue | Money from completed orders, each month |
| 2 | Completed orders | How many orders were completed, each month |
| 3 | Average order value | What a completed order is worth on average, store against online |
| 4 | Cancellation rate | The share of orders placed that were cancelled, each month |
| 5 | High-cancellation months | Which months had a cancellation rate above 9% |

## C1 · Group correctly

1. KPIs 1 and 2 in one query, one row per month.
2. KPI 3, one row per channel.

**Checkpoint C1:** 24 rows for KPIs 1–2 and 2 rows for KPI 3, matching the Check yourself table.

## C2 · A conditional aggregate and a filter on groups

3. KPI 4: for each month, orders placed, cancelled orders and the cancellation rate. Cancelled orders are counted with `COUNTIF`; the rate is the average of a 0/1 column. Do not filter out the other orders.
4. KPI 5: only the months where the rate is above 0.09.

**Checkpoint C2:** KPI 4 returns 24 rows and KPI 5 returns 6.

## C3 · Change the grain

The commercial manager asks: "Is the typical order getting bigger?"

5. Calculate average order value (completed orders) by **year**. What would you tell the manager from this result alone?
6. Add a column that counts how many months of data each year contains: `COUNT(DISTINCT DATE_TRUNC(order_date, MONTH))`. Does that change your answer?
7. Calculate it by **month**. Is there a steady trend?
8. Compare like with like: September 2024–August 2025 against September 2025–August 2026. Use a `CASE` on `order_date` to label the two periods, and group by the label.
9. In your interpretation line, say which result answers the manager's question, and why the yearly one could mislead.

**Checkpoint C3:** your interpretation names the grain you chose and gives the reason.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| C1 | 24 | August 2026: 13,061.50 from 129 orders |
| C1b | 2 | online 109.81; store 116.47 |
| C2 | 24 | January 2025: 12 of 116 cancelled, 0.1034 |
| C2b | 6 | March 2025 is the highest, 0.1111 |
| C3a | 3 | 2024 has 4 months of data; 2026 has 8 |
| C3b | 24 | September 2024: 100.61 |
| C3c | 2 | 115.20, then 113.12 |

If a count differs, check the status and date range before changing the aggregate.

## Hint

For C2, a `WHERE status = 'cancelled'` would remove the orders you need to divide by. For C3 step 8, `CASE WHEN order_date < '2025-09-01' THEN … ELSE … END` gives each order a period label.

## Stretch card

Not required, not checked. In `bigquery-public-data.thelook_ecommerce.orders`, count the orders of each status. Write down the bytes estimate before you run it. The answer changes as the public dataset is updated, so there is no fixed value to check.

## More practice

**Not checked and not submitted.** Solutions are in the Solved file. Nothing on D06 assumes you did these.

- M1 "Which ten products sold the most units?" (`order_items`, all statuses)
- M2 "How many completed orders were delivered on the day they were placed?"
- M3 "How much did we collect in shipping fees each year, on completed orders?"
- M4 "How many new customer accounts did we open each year?"
- O1 Back to life expectancy (`owid.life_expectancy_data`): each country's lowest and highest value since 1950. Keep countries and territories only, as in the D03 lab. If your D03 table is still called `life_expectancy`, `MIN(life_expectancy)` fails with `MIN is not defined for arguments of type STRUCT`: upload it again as `life_expectancy_data` (D03 lab, step 3).
- O2 The average life expectancy of all countries in 2023, and the `World` row for 2023. Why are they different?

## Check yourself: more practice

| Question | Rows returned | One value to check |
|---|---:|---|
| M1 | 10 | P-040 first, 656 units |
| M2 | 1 | 1,763 of 2,771 |
| M3 | 3 | 2025: 502.50 |
| M4 | 4 | 2024: 292 new accounts |
| O1 | 237 | Afghanistan: 28.1563 to 66.0346 |
| O2 | 1 | 74.15 across 237 countries |
| O2b | 1 | World 73.1694 |

## If something goes wrong

| Problem | Fix |
|---|---|
| `SELECT list expression references column … which is neither grouped nor aggregated` | Every column in `SELECT` must be in `GROUP BY` or inside `SUM`, `COUNT`, `AVG` … |
| `Aggregate function AVG not allowed in WHERE clause` | A filter on a calculated group value goes in `HAVING` |
| An amount shows a long tail of decimals | Amounts are stored as `FLOAT`. Round money results: `ROUND(AVG(order_total), 2)` |
| Your month column shows the whole date | That is what `DATE_TRUNC` returns: the first day of the month. It still groups correctly |

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026 ([dataset README](../03-Evr-Upload-Nakheel/Resources/README.md)). Life expectancy, Our World in Data, CC BY 4.0, course copy of 24 September 2026 ([dataset README](../../D03/08-Lab-Life-Expectancy/Resources/README.md)).
