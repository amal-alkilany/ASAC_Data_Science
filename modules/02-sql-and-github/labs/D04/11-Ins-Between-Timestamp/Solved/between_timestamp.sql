-- D04 · 4.5 Instructor Do: BETWEEN on a timestamp drops the last day
-- order_date is a DATE. order_ts is a TIMESTAMP: date and time.

-- August 2026 by date: both ends included.
SELECT COUNT(*) AS august_orders
FROM nakheel.orders
WHERE order_date BETWEEN '2026-08-01' AND '2026-08-31';

-- The same words on the timestamp. '2026-08-31' means midnight at the START of 31 August,
-- so every order placed later that day is left out, with no warning.
SELECT COUNT(*) AS august_orders
FROM nakheel.orders
WHERE order_ts BETWEEN '2026-08-01' AND '2026-08-31';

-- The orders it dropped.
SELECT order_id, order_ts
FROM nakheel.orders
WHERE order_ts >= '2026-08-31'
ORDER BY order_ts;

-- The safe pattern for a timestamp: from the first moment, up to but not including the next month.
SELECT COUNT(*) AS august_orders
FROM nakheel.orders
WHERE order_ts >= '2026-08-01'
  AND order_ts < '2026-09-01';
