-- D04 · 4.4 Everyone Do: conditional counts and rates

-- 1. COUNTIF counts the rows where a condition is true.
-- @check 1
SELECT COUNT(*) AS orders,
       COUNTIF(status = 'cancelled') AS cancelled_orders
FROM nakheel.orders;

-- 2. A 0/1 column averages to a rate: the share of rows where it is 1.
-- @check 2
SELECT ROUND(AVG(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 4) AS cancellation_rate
FROM nakheel.orders;

-- 3. The same counts and rate for each channel. One row of the result is one channel.
-- @check 3
SELECT channel,
       COUNT(*) AS orders,
       COUNTIF(status = 'cancelled') AS cancelled_orders,
       ROUND(AVG(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 4) AS cancellation_rate
FROM nakheel.orders
GROUP BY channel
ORDER BY channel;
