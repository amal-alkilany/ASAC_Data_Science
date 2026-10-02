# Clean text in one line

In this activity, you will fix the D01 problem, "retail" typed three ways, on Nakheel's 500 customers.

**Time:** 7 minutes · **Data:** `nakheel.customers` · **File:** `Solved/clean_text.sql`

## Instructions

1. Open `Solved/clean_text.sql`. Run query 1, `segment` grouped as typed. You should see five values: `Retail`, `retail`, `RETAIL ` (with a space at the end), `Wholesale`, `wholesale`.

2. Run query 2. `LOWER(TRIM(segment))` gives two: `retail` 435, `wholesale` 65. `TRIM` removes spaces at the ends; `LOWER` makes every letter small. The table is not changed; only the result is.

3. Run query 3. `COALESCE(city, 'unknown')` shows a word instead of `NULL`.

4. Look at the cities in query 3. `TRIM` and `LOWER` fix `amman`. They cannot know that `Al Zarqa` is Zarqa. That needs a rule you write yourself, as a `CASE` (D07), or a cleaning step in Power Query in Module 3.

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| 1 | 5 | `Retail` 408 |
| 2 | 2 | retail 435; wholesale 65 |
| 3 | 10 | amman first, 196 |

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
