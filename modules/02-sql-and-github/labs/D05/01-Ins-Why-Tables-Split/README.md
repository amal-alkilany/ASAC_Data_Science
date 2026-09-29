# Why the data is split, and the Five Checks

Instructor Do. Tarek explains why a database keeps customers and orders in separate tables, draws the one-to-many shape, and sets out five checks to run before trusting any join.

**Time:** 15 minutes (2.1 and 2.2) · **Data:** `D03.orders`, `D03.customers` · **File:** `Solved/five_checks.sql`

## Why the data is split

If every order row carried the customer's name and city, a customer who moved house would need their city changed on every order they ever placed. Miss one, and the database disagrees with itself. So the name and city are stored once, in `customers`, and each order stores only `customer_id`, which points to the right customer row.

One customer can have many orders; each order has one customer. That is a **one-to-many** relationship. A **join** puts the columns back side by side for a query, without changing either table.

```text
customers (one row per customer)        orders (one row per order)
customer_id  customer_name   ─── 1 : many ───  order_id  customer_id  status
C-118        Lina Haddad                        1002      C-118        cancelled
                                                1005      C-118        completed
```

## The Five Checks before you trust a join

1. **What is one row in each table?**
2. **Which key joins them?** The column on each side that holds the same value.
3. **Is the key unique on the "one" side?** Compare `COUNT(*)` with `COUNT(DISTINCT key)`. BigQuery does not enforce keys, so check.
4. **How many rows should come out?** Predict before you run. On a one-to-many join, the result has the grain of the "many" side.
5. **What happens to rows with no match?** `INNER JOIN` drops them; `LEFT JOIN` keeps them with empty (`NULL`) columns.

Every join this week, and in Assignment 1, starts with these five.

## References

The D01 tables, course-owned synthetic data, 19 September 2026.
