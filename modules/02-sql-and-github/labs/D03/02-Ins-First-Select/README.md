# Your first SELECT

Instructor Do. Tarek shows the shortest useful query: every column of every row from one table, and what each part of the table's name means.

**Time:** 8 minutes · **Data:** `D03.orders`, `D03.order_items` · **File:** `Solved/first_select.sql`

## What to notice

- `SELECT *` means "every column". `FROM` names the table.
- A full table name is `project.dataset.table`, written in backticks: `` `your-project-id.D03.orders` ``. The query runs inside your project, so you can write `D03.orders`.
- Before pressing **Run**, read the grey line above the results: "This query will process … when run." That is the bytes estimate. Get into the habit of reading it every time. On a five-row table it is tiny; on a public table it can be gigabytes.
- Say how many rows you expect before you run. `D03.orders` has five orders, so five rows.

## References

The D03 tables, course-owned synthetic data, 19 September 2026.
