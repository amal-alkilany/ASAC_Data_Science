# Combine conditions

Instructor Do. Tarek combines conditions with `AND` and `OR`, shows why brackets matter, and introduces four shortcuts: `IN`, `BETWEEN`, `LIKE` and `DISTINCT`.

**Time:** 10 minutes · **Data:** `D03` tables · **File:** `Solved/combine_conditions.sql`

## What to notice

- `AND`: both conditions must be true. `OR`: at least one must be true.
- `AND` is worked out before `OR`. "Completed orders from C-118 or C-204" written without brackets also returns C-118's cancelled order. Put brackets around the `OR` and the answer is right.
- `IN ('C-118', 'C-204')` is a short way to write several `OR`s on one column.
- `BETWEEN '2026-08-01' AND '2026-08-11'` includes both end dates.
- `LIKE 'Omar%'` matches a pattern: `%` stands for any characters, including none. `LIKE` is case-sensitive: `'%Shoe%'` does not find "Trail shoe".
- `SELECT DISTINCT customer_id` shows each value once: five orders, three different customer IDs.

## References

The D03 tables, course-owned synthetic data, 19 September 2026.
