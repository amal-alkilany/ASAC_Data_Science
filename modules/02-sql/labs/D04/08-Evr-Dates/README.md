# Work with dates

In this activity, you will group Nakheel orders by year, by month and by weekday, using three date functions. Count every order, whatever its status: there is no `WHERE` in this activity.

**Time:** 10 minutes · **Data:** `nakheel.orders` · **Starter:** `Unsolved/dates.sql`

## Instructions

1. Orders per year, with `EXTRACT(YEAR FROM order_date)`. Why does 2024 have so few?

2. Orders per month, with `DATE_TRUNC(order_date, MONTH)`. What date does every row of September 2024 become?

3. Orders per weekday, with `FORMAT_DATE('%A', order_date)`. Which day is quietest, and why might that be in Jordan?

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| 1 | 3 | 2024: 425 orders (September to December only) |
| 2 | 24 | 2024-09-01: 123 orders |
| 3 | 7 | Friday is lowest, 357 |

## Hint

`EXTRACT` returns a number. `DATE_TRUNC` returns a date. `FORMAT_DATE` returns text, so `'%Y-%m'` gives `2024-09`, which sorts correctly as text.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
