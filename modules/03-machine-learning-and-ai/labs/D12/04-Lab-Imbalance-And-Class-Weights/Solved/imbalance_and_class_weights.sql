-- D12 · Lab 04 · When the Yes is rare · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · How rare is Yes?
SELECT Attrition, COUNT(*) AS employee_count,
       ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3) AS share
FROM ml.employees
GROUP BY Attrition;

-- Step 2 · A model without help
CREATE OR REPLACE MODEL ml.attrition_plain
OPTIONS (model_type = 'LOGISTIC_REG', input_label_cols = ['Attrition'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2) AS
SELECT Age, Gender, DistanceFromHome, JobLevel, Department, MonthlyIncome,
       PerformanceRating, JobSatisfaction, Attrition
FROM ml.employees;

SELECT ROUND(accuracy, 3) AS accuracy, ROUND(precision, 3) AS precision,
       ROUND(recall, 3) AS recall, ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.attrition_plain);

-- Step 3 · `AUTO_CLASS_WEIGHTS`: make the rare class count
CREATE OR REPLACE MODEL ml.attrition_weighted
OPTIONS (model_type = 'LOGISTIC_REG', input_label_cols = ['Attrition'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         auto_class_weights = TRUE) AS
SELECT Age, Gender, DistanceFromHome, JobLevel, Department, MonthlyIncome,
       PerformanceRating, JobSatisfaction, Attrition
FROM ml.employees;

SELECT ROUND(accuracy, 3) AS accuracy, ROUND(precision, 3) AS precision,
       ROUND(recall, 3) AS recall, ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.attrition_weighted);

-- Step 4 · Which scores moved?
SELECT 'plain' AS model, ROUND(recall, 3) AS recall, ROUND(f1_score, 3) AS f1,
       ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.attrition_plain)
UNION ALL
SELECT 'auto weights', ROUND(recall, 3), ROUND(f1_score, 3), ROUND(roc_auc, 3)
FROM ML.EVALUATE(MODEL ml.attrition_weighted);
WITH pr AS (
  SELECT threshold, recall,
         SAFE_DIVIDE(true_positives, true_positives + false_positives) AS precision
  FROM ML.ROC_CURVE(MODEL ml.attrition_plain)
),
steps AS (
  SELECT precision,
         recall - COALESCE(LAG(recall) OVER (ORDER BY threshold DESC), 0) AS recall_gained
  FROM pr
)
SELECT ROUND(SUM(recall_gained * precision), 3) AS pr_auc
FROM steps;

-- Step 5 · The threshold does something similar
SELECT ROUND(precision, 3) AS precision, ROUND(recall, 3) AS recall
FROM ML.EVALUATE(MODEL ml.attrition_plain, STRUCT(0.2 AS threshold));

-- Step 6 · `CLASS_WEIGHTS`: choose the weights yourself
CREATE OR REPLACE MODEL ml.attrition_custom
OPTIONS (model_type = 'LOGISTIC_REG', input_label_cols = ['Attrition'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         class_weights = [STRUCT('Yes', 3.0), STRUCT('No', 1.0)]) AS
SELECT Age, Gender, DistanceFromHome, JobLevel, Department, MonthlyIncome,
       PerformanceRating, JobSatisfaction, Attrition
FROM ml.employees;

SELECT ROUND(precision, 3) AS precision, ROUND(recall, 3) AS recall
FROM ML.EVALUATE(MODEL ml.attrition_custom);

