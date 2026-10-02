# A cleaning rule of your own

In this activity, you will report completed revenue by city after a join, and write your own cleaning rule as a `CASE` for the spellings that `LOWER` and `TRIM` cannot fix.

**Time:** 12 minutes · **Data:** `nakheel.orders`, `nakheel.customers` · **Starter:** `Unsolved/city_rule.sql`

## Instructions

1. "Completed revenue by city." Nakheel has 8 cities. Predict the row count, then count completed orders by city as typed.

    Translate: `orders LEFT JOIN customers` (the join from [Group by a column from the other table](../04-Ins-Segment-After-Join/README.md)), completed orders only, `GROUP BY c.city`.

    Look at the result. `Amman` and `amman` are two groups, `Zarqa` and `Al Zarqa` are two more, and there is a `NULL` group: customers with no city, plus order 101664, which has no customer at all.

2. `LOWER(TRIM(...))` fixes `amman` (you used it on D04 in [Clean text in one line](../../D04/09-Ins-Clean-Text/README.md)). It cannot know that `Al Zarqa` is Zarqa. That needs a rule you write yourself. Write it in words first, as a comment:

    - no city at all → `unknown`
    - `Al Zarqa` → `zarqa`
    - everything else → trimmed and lower-case

3. Write the rule as a `CASE` column called `city_clean`, and report completed orders and revenue by `city_clean`, largest revenue first.

    Translate: three lines in the `CASE`, in the order of your rule; `GROUP BY city_clean`; `ROUND(SUM(o.order_total), 2)`.

4. Why does `WHEN c.city IS NULL` come first? `LOWER(TRIM(NULL))` is `NULL`, so an `ELSE` line would return `NULL`, not `unknown`. `CASE` stops at the first true line, so the order of the lines matters.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 11 | the `NULL` group has 37 orders |
| 3 | 9 | amman first: 1,064 orders, 130,848.00; zarqa 284 orders; unknown 37 orders, 3,197.00 |

In step 3, 10 rows means the `Al Zarqa` line is missing. A blank row instead of `unknown` means the `IS NULL` line is last or missing.

## Hint

A `CASE` can use a function inside its test: `WHEN LOWER(TRIM(c.city)) = 'al zarqa' THEN 'zarqa'`.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../../D04/03-Evr-Upload-Nakheel/Resources/README.md).
