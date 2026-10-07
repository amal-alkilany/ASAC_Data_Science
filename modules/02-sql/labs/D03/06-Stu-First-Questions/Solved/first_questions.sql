-- D03 · 5.1 Student Do: first questions on D03

-- Q1 Which orders were cancelled? Order number and date.
-- One row is one order.
-- @check 1
SELECT order_id, order_date
FROM D03.orders
WHERE status = 'cancelled';

-- Q2 Every order line that sold for more than 15 dinars a unit, most expensive first.
-- One row is one product on one order.
-- @check 2
SELECT item_id, order_id, product_id, price
FROM D03.order_items
WHERE price > 15
ORDER BY price DESC, item_id;

-- Q3 Which customers have we got no city for?
-- One row is one customer record.
-- @check 3
SELECT customer_id, customer_name
FROM D03.customers
WHERE city IS NULL;

-- Q4 Which orders has customer C-118 placed with us? Newest first.
-- One row is one order.
-- @check 4
SELECT order_id, order_date, status
FROM D03.orders
WHERE customer_id = 'C-118'
ORDER BY order_date DESC;

-- Bonus: every retail customer, however "retail" was typed, without typing the spellings.
-- Works here because the only other segment is Wholesale and no segment is empty.
-- @check Bonus
SELECT customer_id, customer_name, segment
FROM D03.customers
WHERE segment <> 'Wholesale';
