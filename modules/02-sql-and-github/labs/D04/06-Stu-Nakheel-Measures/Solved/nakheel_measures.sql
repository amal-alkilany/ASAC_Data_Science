-- D04 · 3.4 Student Do: first measures on Nakheel

-- Q1 Completed orders and their value, by channel.
-- One row of the result is one channel.
-- @check 1
SELECT channel,
       COUNT(*) AS completed_orders,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
GROUP BY channel
ORDER BY revenue DESC;

-- Q2 Months of 2025 with completed revenue above 13,000 dinars.
-- One row of the result is one month.
-- @check 2
SELECT DATE_TRUNC(order_date, MONTH) AS month,
       ROUND(SUM(order_total), 2) AS revenue
FROM nakheel.orders
WHERE status = 'completed'
  AND order_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY month
HAVING SUM(order_total) > 13000
ORDER BY month;

-- Q3 Customers per city, as the city was typed. Biggest first.
-- One row of the result is one spelling of a city.
-- @check 3
SELECT city, COUNT(*) AS customers
FROM nakheel.customers
GROUP BY city
ORDER BY customers DESC, city;

-- Bonus: the single day with the most orders.
-- @check Bonus
SELECT order_date, COUNT(*) AS orders
FROM nakheel.orders
GROUP BY order_date
ORDER BY orders DESC, order_date
LIMIT 1;
