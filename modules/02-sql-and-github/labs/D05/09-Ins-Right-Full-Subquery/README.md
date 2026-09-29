# The join family, UNION and CROSS JOIN, and a preview of D06

Instructor Do, steps 4.5 to 4.7. For recognition: `RIGHT JOIN`, `FULL OUTER JOIN` and the no-match joins (4.5), `UNION ALL` and `UNION DISTINCT` (4.6), and `CROSS JOIN` (4.7). The folder keeps its original name so that no other link moves.

**Time:** 18 minutes over three steps · **Data:** `nakheel.orders`, `nakheel.customers`, `nakheel.order_items`, and the `D03` tables · **Files:** `Solved/right_full_subquery.sql` (4.5), `Solved/union.sql` (4.6), `Solved/cross_join.sql` (4.7)

## What to notice

- **Which rows each join keeps.** With `customers` written first: `INNER JOIN` 2,999 rows, `LEFT JOIN` 3,038, `RIGHT JOIN` 3,000 (every order, including the orphan 101664), `FULL OUTER JOIN` 3,039.
- `orders RIGHT JOIN customers` returns the same 3,038 rows as `customers LEFT JOIN orders`. A `RIGHT JOIN` is a `LEFT JOIN` with the tables swapped. Most analysts write `LEFT JOIN` and put the table they want to keep first.
- **The no-match joins.** `LEFT JOIN` then `WHERE o.order_id IS NULL` keeps the 39 customers with no order; the same idea from the right keeps the 1 order with no customer. Power Query calls these a left anti join and a right anti join.
- **UNION stacks rows.** A join adds columns; `UNION` adds rows. Both queries need the same number of columns, in the same order, with matching types, and the result takes its names from the first query. On `D03`: 2 customers in Amman and 4 completed-order customers give 6 rows with `UNION ALL` and 4 with `UNION DISTINCT`. `DISTINCT` removes C-118, which is in both lists, and the second C-204, which repeats inside the second list.
- **BigQuery-specific:** a bare `UNION` is a syntax error in BigQuery (`Expected keyword ALL or keyword DISTINCT`). Most other databases accept it and read it as `DISTINCT`. The last query in `union.sql` shows the error on purpose.
- **CROSS JOIN pairs every row with every row.** There is no `ON`: 5 customers × 5 orders = 25 rows on `D03`, and 500 × 3,000 = 1,500,000 on Nakheel. Keeping the 5 pairs whose keys match gives the `INNER JOIN` from 2.3.
- One use: every customer against every category, so the pairs with no sale still get a row. Four `D03` customers never bought Outerwear.
- The last query in `right_full_subquery.sql` summarises `order_items` to one row per order **before** joining. Then both sides have one row per order, `order_total` is not copied, and revenue by channel is right (store 205,338.00; online 110,685.50) next to units sold. The inner `SELECT` in brackets is a subquery. D06 teaches it properly.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../../D04/03-Evr-Upload-Nakheel/Resources/README.md). `D03`: the D01 tables, course-owned synthetic data written 19 September 2026.
