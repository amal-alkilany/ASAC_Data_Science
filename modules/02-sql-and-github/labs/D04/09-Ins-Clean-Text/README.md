# Clean text in one line

Instructor Do. Tarek fixes the D01 problem, "retail" typed three ways, on Nakheel's 500 customers.

**Time:** 7 minutes · **Data:** `nakheel.customers` · **File:** `Solved/clean_text.sql`

## What to notice

- Grouped as typed, `segment` has five values: `Retail`, `retail`, `RETAIL ` (trailing space), `Wholesale`, `wholesale`.
- `LOWER(TRIM(segment))` gives two: `retail` 435, `wholesale` 65. `TRIM` removes spaces at the ends; `LOWER` makes every letter small. The table is not changed; only the result is.
- `COALESCE(city, 'unknown')` shows a word instead of `NULL`.
- `TRIM` and `LOWER` fix `amman`. They cannot know that `Al Zarqa` is Zarqa. That needs a rule you write, as a `CASE`, or a cleaning step in Power Query in Module 3.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
