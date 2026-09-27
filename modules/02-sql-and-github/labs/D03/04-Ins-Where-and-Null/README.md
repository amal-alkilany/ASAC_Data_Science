# Filter rows with WHERE

Instructor Do. Tarek filters rows with `WHERE`, then writes two filters the way most people would. BigQuery refuses to run the first one. The second runs and gives the wrong answer, with no warning.

**Time:** 8 minutes · **Data:** `D03.orders`, `D03.order_items`, `D03.customers` · **File:** `Solved/where_and_null.sql`

## What to notice

- `WHERE` keeps the rows where the condition is true. Text goes in single quotes (`'completed'`); numbers do not (`price > 20`).
- `=`, `<>` (not equal), `>`, `>=`, `<`, `<=`.
- `WHERE city = NULL` does not run. BigQuery stops with `Operands of = cannot be literal NULL`. `NULL` means "no value", and a comparison with "no value" is never true, not even `NULL = NULL`, so this filter could never keep a row. Use `IS NULL` and `IS NOT NULL`.
- `WHERE segment = 'retail'` returns one customer. There are three retail customers, typed `Retail`, `retail` and `RETAIL ` (with a space at the end). Text comparison is exact. Look at every spelling in a column before you filter on it.

## BigQuery does this differently

In PostgreSQL, SQL Server and MySQL, `WHERE city = NULL` runs, returns 0 rows and gives no warning. BigQuery checks the query before it runs, sees a comparison with the word `NULL` that can never be true, and stops with an error. The rule is the same in every database; BigQuery tells you sooner. It cannot catch every case: `WHERE city = other_city`, where one side happens to be empty, still leaves those rows out silently. That is why `IS NULL` is the habit to learn, not the error message.

Source: GoogleSQL for BigQuery, [Comparison operators](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/operators#comparison_operators) and [`IS` operators](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/operators#is_operators). The error text is BigQuery's own.

## References

The D03 tables, course-owned synthetic data, 19 September 2026.
