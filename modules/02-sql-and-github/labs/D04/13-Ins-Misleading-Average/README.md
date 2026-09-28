# The misleading average

Instructor Do. Tarek answers "what does a typical order cost?" twice, at two different grains, and both answers are correct.

**Time:** 10 minutes · **Data:** `nakheel.orders`, `nakheel.order_items` · **File:** `Solved/misleading_average.sql`

## What to notice

- Average value of one order **line** (one product on one order), completed orders: 45.46 dinars.
- Average value of one **order**, completed orders: 114.05 dinars.
- Both are averages of the same money. They differ because one row means something different in each table. Before you report an average, say what one row is.
- 2,082 of the 2,771 completed orders are below the 114.05 average. A few very large wholesale orders pull it up. "Typical" and "average" are not the same word.
- The first query uses `IN (SELECT …)` to keep the lines of completed orders. That is a subquery, and D06 covers it; for now, read it as "the order IDs of completed orders".

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
