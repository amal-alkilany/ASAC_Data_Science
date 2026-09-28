# Make a column from a rule

Instructor Do. Tarek writes a business rule in words, turns it into a `CASE` expression, and groups by the new column.

**Time:** 8 minutes · **Data:** `nakheel.orders` · **File:** `Solved/case_rules.sql`

## What to notice

- Write the rule in words first: "An order is large from 200 dinars, medium from 50, otherwise small."
- `CASE` checks the `WHEN` lines from the top and stops at the first one that is true. That is why the 200 line comes before the 50 line. Swap them and no order is ever large.
- A `CASE` column can be grouped like any other column. Completed orders: 317 large, 1,342 medium, 1,112 small.
- Large orders are 11% of completed orders and almost half of completed revenue.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
