-- D13 · Lab 07 · Heavy tails, logs, and grouping by mix: a wholesaler's clients · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · Look at the spending first
SELECT APPROX_QUANTILES(fresh, 4) AS fresh_quartiles,
       ROUND(AVG(fresh)) AS fresh_avg,
       APPROX_QUANTILES(detergents_paper, 4) AS detergents_quartiles,
       ROUND(AVG(detergents_paper)) AS detergents_avg
FROM ml.wholesale;

-- Step 2 · Scaled, but not logged
CREATE OR REPLACE MODEL ml.wholesale_scaled
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT fresh, milk, grocery, frozen, detergents_paper, delicatessen
FROM ml.wholesale;

SELECT centroid_id, COUNT(*) AS clients,
       ROUND(COUNTIF(channel = 'Retail') / COUNT(*), 2) AS share_retail,
       APPROX_QUANTILES(fresh, 2)[OFFSET(1)] AS median_fresh,
       APPROX_QUANTILES(grocery, 2)[OFFSET(1)] AS median_grocery
FROM ML.PREDICT(MODEL ml.wholesale_scaled, (SELECT * FROM ml.wholesale))
GROUP BY centroid_id
ORDER BY clients DESC;

-- Step 3 · Logs first, then scaling
CREATE OR REPLACE VIEW ml.wholesale_logs AS
SELECT *,
       LN(1 + fresh) AS log_fresh, LN(1 + milk) AS log_milk, LN(1 + grocery) AS log_grocery,
       LN(1 + frozen) AS log_frozen, LN(1 + detergents_paper) AS log_detergents_paper,
       LN(1 + delicatessen) AS log_delicatessen
FROM ml.wholesale;

CREATE OR REPLACE MODEL ml.wholesale_log_model
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT log_fresh, log_milk, log_grocery, log_frozen, log_detergents_paper, log_delicatessen
FROM ml.wholesale_logs;

SELECT centroid_id, COUNT(*) AS clients,
       ROUND(COUNTIF(channel = 'Retail') / COUNT(*), 2) AS share_retail,
       APPROX_QUANTILES(fresh, 2)[OFFSET(1)] AS median_fresh,
       APPROX_QUANTILES(milk, 2)[OFFSET(1)] AS median_milk,
       APPROX_QUANTILES(grocery, 2)[OFFSET(1)] AS median_grocery,
       APPROX_QUANTILES(detergents_paper, 2)[OFFSET(1)] AS median_detergents
FROM ML.PREDICT(MODEL ml.wholesale_log_model, (SELECT * FROM ml.wholesale_logs))
GROUP BY centroid_id
ORDER BY clients DESC;

-- Step 4 · Group by the mix, not the size
CREATE OR REPLACE MODEL ml.wholesale_cosine
OPTIONS (model_type = 'KMEANS', num_clusters = 2, kmeans_init_method = 'KMEANS++',
         distance_type = 'COSINE', standardize_features = FALSE) AS
SELECT fresh, milk, grocery, frozen, detergents_paper, delicatessen
FROM ml.wholesale;

SELECT centroid_id, channel, COUNT(*) AS clients
FROM ML.PREDICT(MODEL ml.wholesale_cosine, (SELECT * FROM ml.wholesale))
GROUP BY centroid_id, channel
ORDER BY centroid_id, channel;
