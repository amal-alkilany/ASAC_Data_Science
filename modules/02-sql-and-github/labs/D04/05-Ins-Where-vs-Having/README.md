# WHERE filters rows, HAVING filters groups

Instructor Do. Tarek filters Nakheel orders before grouping, then filters the groups after counting.

**Time:** 5 minutes · **Data:** `nakheel.orders` · **File:** `Solved/where_vs_having.sql`

## What to notice

- `WHERE status = 'completed'` removes rows **before** they are grouped.
- `HAVING COUNT(*) > 20` removes groups **after** they are counted. 25 customers have more than 20 orders; 22 have more than 20 completed orders.
- `WHERE COUNT(*) > 20` fails: `Aggregate function COUNT not allowed in WHERE clause`. There is nothing to count yet when `WHERE` runs.
- The run order from D03 grows two steps: **FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT**.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
