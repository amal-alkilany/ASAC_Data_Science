-- D07 · 5.1 Everyone Do: A bridge table: films per category
-- Tables: pagila.film, pagila.film_category, pagila.category
-- film: one film. category: one category. film_category: one film in one category (the bridge table).

-- Step 2. Film 1, ACADEMY DINOSAUR, in the bridge table: three rows, one per category. (3 rows: Games, New, Travel)
-- @check 2
SELECT fc.film_id, c.name AS category
FROM pagila.film_category AS fc
INNER JOIN pagila.category AS c
  ON fc.category_id = c.category_id
WHERE fc.film_id = 1
ORDER BY category;

-- Step 3. Audit: film alone. (1,000)
-- @check 3
SELECT COUNT(*) AS film_rows
FROM pagila.film;

-- Step 4. Audit: after joining film_category. More rows than films. (2,367 rows; 1,000 films)
-- @check 4
SELECT COUNT(*) AS row_count,
       COUNT(DISTINCT f.film_id) AS different_films
FROM pagila.film AS f
INNER JOIN pagila.film_category AS fc
  ON f.film_id = fc.film_id;

-- Step 5. Films per category.
-- One row is: one category. (16 rows; Drama and Music 152 each. The 16 counts add up to 2,367, not 1,000.)
-- @check 5
SELECT c.name AS category,
       COUNT(*) AS films
FROM pagila.film AS f
INNER JOIN pagila.film_category AS fc
  ON f.film_id = fc.film_id
INNER JOIN pagila.category AS c
  ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY films DESC, category;

-- Step 7. The catalogue's rental_rate total on film alone. (2,980.00)
-- @check 7
SELECT ROUND(SUM(rental_rate), 2) AS rental_rate_total
FROM pagila.film;

-- Step 7b. The same sum after the join through the bridge table: fan-out again. (7,077.33)
-- @check 7b
SELECT ROUND(SUM(f.rental_rate), 2) AS rental_rate_after_join
FROM pagila.film AS f
INNER JOIN pagila.film_category AS fc
  ON f.film_id = fc.film_id;

-- Review (5.2). How many categories does each film have? (3 rows: 36 films have 1, 561 have 2, 403 have 3)
-- It uses a subquery, which is D08: look at the result, not the syntax.
-- One row is: a number of categories
-- @check Review
SELECT categories, COUNT(*) AS films
FROM (
  SELECT film_id, COUNT(*) AS categories
  FROM pagila.film_category
  GROUP BY film_id
) AS per_film
GROUP BY categories
ORDER BY categories;
