# Define a KPI before you calculate it

In this activity, you will write three KPIs as a definition table (name, rule in words, grain) and then as one query.

**Time:** 15 minutes · **Data:** `nakheel.orders` · **Starter:** `Unsolved/kpi_definitions.sql`

A KPI (key performance indicator) is a number a business agrees to track the same way every time. Two analysts who calculate "revenue" differently will report different numbers to the same manager. Writing the rule down first stops that.

## Instructions

1. Fill in the definition table in the starter file for three KPIs: completed revenue, completed orders, and average order value. For each, write the rule in words and the grain: what one row of the result is.

2. The three KPIs share a grain, one month. Write one query that returns all three, one row per month.

3. Compare August 2025 with August 2026. Which KPI moved, and in which direction?

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| 1 | 24 | 2024-09-01: 11,268.00 from 112 orders; average 100.61 |

## Hint

Average order value is completed revenue divided by completed orders: `SUM(order_total) / COUNT(*)`, with the same `WHERE`. `AVG(order_total)` gives the same number here.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
