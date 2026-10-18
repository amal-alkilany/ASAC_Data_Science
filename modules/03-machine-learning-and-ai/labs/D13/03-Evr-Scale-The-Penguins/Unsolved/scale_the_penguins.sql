-- D13 · 03 · Grams against millimetres: the penguins, with and without scaling · Starter
-- Run one numbered block at a time. The public table needs your ml dataset in the US location.

-- 1. How spread out is each column? (standard deviation, in its own units)
SELECT ROUND(STDDEV(culmen_length_mm), 1) AS sd_bill_length_mm,
       ROUND(STDDEV(culmen_depth_mm), 1) AS sd_bill_depth_mm,
       ROUND(STDDEV(flipper_length_mm), 1) AS sd_flipper_mm,
       ROUND(STDDEV(body_mass_g), 1) AS sd_mass_g
FROM `bigquery-public-data.ml_datasets.penguins`
WHERE body_mass_g IS NOT NULL;

-- 2. Three groups from the four measurements as they are: scaling switched off.
CREATE OR REPLACE MODEL ml.penguins_raw
OPTIONS (
  model_type = 'KMEANS',
  num_clusters = 3,
  kmeans_init_method = 'KMEANS++',
  standardize_features = FALSE
) AS
SELECT culmen_length_mm, culmen_depth_mm, flipper_length_mm, body_mass_g
FROM `bigquery-public-data.ml_datasets.penguins`
WHERE body_mass_g IS NOT NULL;

-- 3. Each group against the species the model never saw.
SELECT centroid_id, species, COUNT(*) AS penguins,
       MIN(body_mass_g) AS lightest_g, MAX(body_mass_g) AS heaviest_g
FROM ML.PREDICT(MODEL ml.penguins_raw,
       (SELECT * FROM `bigquery-public-data.ml_datasets.penguins` WHERE body_mass_g IS NOT NULL))
GROUP BY centroid_id, species
ORDER BY lightest_g, species;

-- 4. The same, with each column scaled to standard deviations from its average.
CREATE OR REPLACE MODEL ml.penguins_scaled
OPTIONS (
  model_type = 'KMEANS',
  num_clusters = 3,
  kmeans_init_method = 'KMEANS++',
  standardize_features = TRUE
) AS
SELECT culmen_length_mm, culmen_depth_mm, flipper_length_mm, body_mass_g
FROM `bigquery-public-data.ml_datasets.penguins`
WHERE body_mass_g IS NOT NULL;

-- 5. Compare with species again.
SELECT centroid_id, species, COUNT(*) AS penguins
FROM ML.PREDICT(MODEL ml.penguins_scaled,
       (SELECT * FROM `bigquery-public-data.ml_datasets.penguins` WHERE body_mass_g IS NOT NULL))
GROUP BY centroid_id, species
ORDER BY centroid_id, species;
