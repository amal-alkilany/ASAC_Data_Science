-- D13 · Lab 09 (optional, self-study) · Nakheel's customers, by rule and by k-means · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · Look at the three columns
SELECT COUNT(*) AS customers,
       APPROX_QUANTILES(days_since_last, 4) AS days_quartiles,
       APPROX_QUANTILES(orders_before, 4) AS orders_quartiles,
       APPROX_QUANTILES(revenue_before, 4) AS spend_quartiles
FROM ml.customer_features;

-- Step 2 · Tiers the business way: RFM
CREATE OR REPLACE VIEW ml.customer_rfm AS
SELECT customer_id, days_since_last, orders_before, revenue_before, revenue_next_6m,
       NTILE(4) OVER (ORDER BY days_since_last, customer_id) AS r_tier,
       NTILE(4) OVER (ORDER BY orders_before DESC, customer_id) AS f_tier,
       NTILE(4) OVER (ORDER BY revenue_before DESC, customer_id) AS m_tier
FROM ml.customer_features;

SELECT CONCAT(CAST(r_tier AS STRING), CAST(f_tier AS STRING), CAST(m_tier AS STRING)) AS rfm, COUNT(*) AS customers
FROM ml.customer_rfm
GROUP BY rfm
ORDER BY customers DESC
LIMIT 6;

-- Step 3 · k-means on the raw columns
CREATE OR REPLACE MODEL ml.nakheel_seg_a
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = FALSE) AS
SELECT days_since_last, orders_before, revenue_before
FROM ml.customer_features;

SELECT centroid_id, COUNT(*) AS customers
FROM ML.PREDICT(MODEL ml.nakheel_seg_a, (SELECT * FROM ml.customer_features))
GROUP BY centroid_id
ORDER BY customers DESC;

-- Step 4 · Scaled
CREATE OR REPLACE MODEL ml.nakheel_seg_b
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT days_since_last, orders_before, revenue_before
FROM ml.customer_features;

SELECT centroid_id, COUNT(*) AS customers
FROM ML.PREDICT(MODEL ml.nakheel_seg_b, (SELECT * FROM ml.customer_features))
GROUP BY centroid_id
ORDER BY customers DESC;

-- Step 5 · Logs, then scaled
CREATE OR REPLACE VIEW ml.customer_features_log AS
SELECT *, LN(1 + orders_before) AS log_orders, LN(1 + revenue_before) AS log_revenue
FROM ml.customer_features;

CREATE OR REPLACE MODEL ml.nakheel_seg_c
OPTIONS (model_type = 'KMEANS', num_clusters = 4, kmeans_init_method = 'KMEANS++',
         standardize_features = TRUE) AS
SELECT days_since_last, log_orders, log_revenue
FROM ml.customer_features_log;

-- Step 6 · Profile, and check against what happened next
SELECT centroid_id, COUNT(*) AS customers,
       ROUND(AVG(days_since_last)) AS avg_days,
       ROUND(AVG(orders_before), 1) AS avg_orders,
       ROUND(AVG(revenue_before)) AS avg_spend,
       ROUND(AVG(revenue_next_6m)) AS avg_spend_after,
       ROUND(COUNTIF(revenue_next_6m = 0) / COUNT(*), 2) AS share_bought_nothing_after
FROM ML.PREDICT(MODEL ml.nakheel_seg_c, (SELECT * FROM ml.customer_features_log))
GROUP BY centroid_id
ORDER BY avg_spend;

-- Step 7 · Rules against clusters
SELECT r.r_tier, p.centroid_id, COUNT(*) AS customers
FROM ML.PREDICT(MODEL ml.nakheel_seg_c, (SELECT * FROM ml.customer_features_log)) AS p
JOIN ml.customer_rfm AS r USING (customer_id)
GROUP BY r.r_tier, p.centroid_id
ORDER BY r.r_tier, p.centroid_id;
