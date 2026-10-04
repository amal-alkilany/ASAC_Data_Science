-- D03 · 4.1 Instructor Do: SELECT and FROM
-- Table: D03.orders. One row is one order.

-- The full name is project.dataset.table. Backticks are needed because
-- project IDs contain hyphens. Replace your-project-id with yours.
-- @check 1
SELECT *
FROM `your-project-id.D03.orders`;

-- The query runs in your project, so the project part can be left out.
-- Predict first: how many rows? (5)
-- @check 2
SELECT *
FROM D03.orders;

-- Same idea, another table. Predict: how many rows? (12)
-- @check 3
SELECT *
FROM D03.order_items;
