# Sum each amount where it lives

Instructor Do. Tarek shows the inflated revenue by channel, then two correct fixes, and counts orders correctly after a join.

**Time:** 10 minutes · **Data:** `nakheel.orders`, `nakheel.order_items` · **File:** `Solved/sum_where_it_lives.sql`

## What to notice

- `SUM(o.order_total)` after the join: store 637,238.00, online 351,733.50. About three times the truth, and nothing warns you.
- Fix 1: sum the amount stored at the grain of the joined result, `SUM(i.qty * i.price)`: store 205,338.00, online 110,685.50.
- Fix 2: an amount stored on `orders` needs no join. Sum it on `orders` alone: the same two numbers.
- Counting orders after the join: `COUNT(DISTINCT o.order_id)`, not `COUNT(*)`.
- `shipping_fee` lives on `orders` too, so it inflates the same way: 1,742.50 after the join against 1,032.50 on `orders`.

The rule: **sum an amount at the table where it lives, or check that the join has not changed that table's grain.**

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [the dataset README](../../D04/03-Evr-Upload-Nakheel/Resources/README.md).
