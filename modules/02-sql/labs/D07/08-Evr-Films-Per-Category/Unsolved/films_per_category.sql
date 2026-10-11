-- D07 · 5.1 Everyone Do: A bridge table: films per category
-- Tables: pagila.film, pagila.film_category, pagila.category
--
-- Audit table (fill in as you go)
-- | Step                       | Rows | Different films | SUM(rental_rate) |
-- |----------------------------|------|-----------------|------------------|
-- | film alone                 |      |                 |                  |
-- | + film_category            |      |                 |                  |

-- Step 2. Film 1 in film_category: fc.film_id and the category name AS category, sorted by category.


-- Step 3. Audit: rows in film.


-- Step 4. Audit: rows and different films after film INNER JOIN film_category.


-- Step 5. Films per category: the name AS category, the count AS films. Largest count first, then by category.
-- One row is:
-- Result check:


-- Step 6. Interpretation: why do the category counts add up to more than 1,000?
--


-- Step 7. SUM(rental_rate) on film alone, then after the join to film_category. Round both to 2 decimals.
-- Interpretation:

