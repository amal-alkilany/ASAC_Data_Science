-- D14 · Lab 11 (optional, self-study) · Nakheel's spend, with trees · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · Three fixed groups of customers
CREATE OR REPLACE VIEW ml.customer_groups AS
SELECT *,
       CASE MOD(ROW_NUMBER() OVER (ORDER BY customer_id), 5)
         WHEN 3 THEN 'validation'
         WHEN 4 THEN 'test'
         ELSE 'train'
       END AS split
FROM ml.customer_features;

SELECT split, COUNT(*) AS customers, ROUND(AVG(revenue_next_6m), 2) AS avg_next_6m
FROM ml.customer_groups
GROUP BY split
ORDER BY customers DESC;

-- Step 2 · Three models, the same features
CREATE OR REPLACE MODEL ml.spend_linear
OPTIONS (model_type = 'LINEAR_REG', input_label_cols = ['revenue_next_6m'], data_split_method = 'NO_SPLIT') AS
SELECT segment, city, orders_before, revenue_before, avg_order_value,
       days_since_last, tenure_days, online_share, revenue_next_6m
FROM ml.customer_groups WHERE split = 'train';

CREATE OR REPLACE MODEL ml.spend_boosted
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR', input_label_cols = ['revenue_next_6m'], data_split_method = 'NO_SPLIT') AS
SELECT segment, city, orders_before, revenue_before, avg_order_value,
       days_since_last, tenure_days, online_share, revenue_next_6m
FROM ml.customer_groups WHERE split = 'train';

CREATE OR REPLACE MODEL ml.spend_forest
OPTIONS (model_type = 'RANDOM_FOREST_REGRESSOR', input_label_cols = ['revenue_next_6m'], data_split_method = 'NO_SPLIT') AS
SELECT segment, city, orders_before, revenue_before, avg_order_value,
       days_since_last, tenure_days, online_share, revenue_next_6m
FROM ml.customer_groups WHERE split = 'train';

-- Step 3 · Score them on the same 82 customers
SELECT 'linear' AS model, ROUND(mean_absolute_error) AS mae, ROUND(r2_score, 2) AS r2
FROM ML.EVALUATE(MODEL ml.spend_linear, (SELECT * FROM ml.customer_groups WHERE split = 'validation'))
UNION ALL
SELECT 'boosted trees', ROUND(mean_absolute_error), ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.spend_boosted, (SELECT * FROM ml.customer_groups WHERE split = 'validation'))
UNION ALL
SELECT 'random forest', ROUND(mean_absolute_error), ROUND(r2_score, 2)
FROM ML.EVALUATE(MODEL ml.spend_forest, (SELECT * FROM ml.customer_groups WHERE split = 'validation'));

-- Step 4 · Below zero
SELECT 'linear' AS model, COUNTIF(predicted_revenue_next_6m < 0) AS negative_predictions
FROM ML.PREDICT(MODEL ml.spend_linear, (SELECT * FROM ml.customer_groups))
UNION ALL
SELECT 'random forest', COUNTIF(predicted_revenue_next_6m < 0)
FROM ML.PREDICT(MODEL ml.spend_forest, (SELECT * FROM ml.customer_groups));

-- Step 5 · Choose, then test once
SELECT ROUND(mean_absolute_error) AS mae, ROUND(r2_score, 2) AS r2
FROM ML.EVALUATE(MODEL ml.spend_forest, (SELECT * FROM ml.customer_groups WHERE split = 'test'));
