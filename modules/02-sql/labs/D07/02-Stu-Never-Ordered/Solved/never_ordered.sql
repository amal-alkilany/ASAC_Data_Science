-- D07 · 2.2 Student Do: Never ordered, never sold

-- Q1 Customers who have never placed an order.
-- One row is one customer record.
-- @check 1
SELECT c.customer_id, c.customer_name, c.city, c.signup_date
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Q2 Products that have never been sold.
-- One row is one product.
-- @check 2
SELECT p.product_id, p.product_name, p.category
FROM nakheel.products AS p
LEFT JOIN nakheel.order_items AS i
  ON p.product_id = i.product_id
WHERE i.item_id IS NULL
ORDER BY p.product_id;

-- Bonus: customers who never ordered, per city as typed.
-- @check Bonus
SELECT c.city, COUNT(*) AS customers_without_orders
FROM nakheel.customers AS c
LEFT JOIN nakheel.orders AS o
  ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
GROUP BY c.city
ORDER BY customers_without_orders DESC, c.city;
