# The top three in every category

In this activity, you will answer "What are the three best-selling products by revenue in each category?" twice: with a CTE and `WHERE`, then with `QUALIFY`, BigQuery's shortcut for filtering on a window.

**Time:** 13 minutes · **Data:** `nakheel.order_items`, `nakheel.orders`, `nakheel.products` · **Starter:** `Unsolved/top_three.sql`

## Instructions

1. **Rank the products inside each category by revenue.** Start from the `product_revenue` CTE in the starter (one row per product, 56 rows). Select `category`, `product_name` and `revenue`, and add:

    ```sql
    RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
    ```

    You should see 56 rows. Denim jacket is 1 in Outerwear with 12,818.00.

2. **Keep the top three, the long way.** A window cannot go in `WHERE` (you saw why in 2.1). Put the ranking in a second CTE, `ranked`, and filter it:

    ```sql
    SELECT category, product_name, revenue, revenue_rank
    FROM ranked
    WHERE revenue_rank <= 3
    ORDER BY category, revenue_rank;
    ```

    You should see 18 rows: three per category.

3. **The same, with `QUALIFY`.** `QUALIFY` filters on a window function's result, the way `HAVING` filters on an aggregate. Remove the `ranked` CTE and write:

    ```sql
    SELECT category,
           product_name,
           revenue,
           RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS revenue_rank
    FROM product_revenue
    QUALIFY revenue_rank <= 3
    ORDER BY category, revenue_rank;
    ```

    You should see the same 18 rows.

    - The clauses run in this order: `FROM`, `WHERE`, `GROUP BY`, `HAVING`, the window, `QUALIFY`, `ORDER BY`.
    - `QUALIFY` is BigQuery-specific. Snowflake and Databricks have it too; PostgreSQL and SQL Server do not, so there you use the CTE from step 2.

4. Why `RANK` and not `ROW_NUMBER`? If two products tied for third, `RANK` would keep both and `ROW_NUMBER` would drop one at random. Here there is no tie in the top three, so both give 18 rows.

## Check yourself

| Step | Rows returned | One value to check |
|---|---:|---|
| 1 | 56 | Denim jacket, Outerwear, rank 1, 12,818.00 |
| 2 | 18 | Accessories: Leather belt, Backpack, Canvas cap |
| 3 | 18 | the same rows as step 2 |

## Hint

If BigQuery says `Unrecognized name: revenue_rank` in a `WHERE`, the `WHERE` is in the same `SELECT` as the window that names it. Use step 2's second CTE or step 3's `QUALIFY`.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../../../../../shared/datasets/nakheel/README.md).
