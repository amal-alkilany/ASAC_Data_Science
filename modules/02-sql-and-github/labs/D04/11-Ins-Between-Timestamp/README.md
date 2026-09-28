# BETWEEN on a timestamp

Instructor Do. Tarek counts August 2026 orders twice with the same `BETWEEN`, once on the date and once on the timestamp, and gets two different answers.

**Time:** 5 minutes · **Data:** `nakheel.orders` · **File:** `Solved/between_timestamp.sql`

## What to notice

- `order_date BETWEEN '2026-08-01' AND '2026-08-31'` → 158 orders.
- `order_ts BETWEEN '2026-08-01' AND '2026-08-31'` → 153. On a timestamp, `'2026-08-31'` means midnight at the start of 31 August, so the five orders placed later that day are dropped, with no warning.
- For a timestamp, use "from the first moment, up to but not including the next period": `order_ts >= '2026-08-01' AND order_ts < '2026-09-01'` → 158.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../03-Evr-Upload-Nakheel/Resources/README.md).
