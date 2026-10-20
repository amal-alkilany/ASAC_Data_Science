-- D12 · Lab 03 · Thresholds and curves · Solved (every query from the README, in order)
-- Self-guided: run one statement at a time.

-- Step 1 · The whole ROC curve
SELECT ROUND(threshold, 3) AS threshold,
       true_positives, false_positives, false_negatives, true_negatives,
       ROUND(recall, 3) AS recall, ROUND(false_positive_rate, 3) AS false_positive_rate
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY threshold;

-- Step 2 · The confusion matrix at any threshold
SELECT * FROM ML.CONFUSION_MATRIX(MODEL ml.churn_model, STRUCT(0.3 AS threshold));
SELECT * FROM ML.CONFUSION_MATRIX(MODEL ml.churn_model, STRUCT(0.7 AS threshold));

-- Step 3 · `ML.METRICS`: the same scores from any table of predictions
SELECT ROUND(precision, 3) AS precision, ROUND(recall, 3) AS recall,
       ROUND(accuracy, 3) AS accuracy, ROUND(f1_score, 3) AS f1_score
FROM ML.METRICS(
  (SELECT predicted_Churn = 'Yes' AS predicted_leave,
          Churn = 'Yes' AS actual_leave
   FROM ML.PREDICT(MODEL ml.churn_model, (SELECT * FROM ml.telco), STRUCT(0.5 AS threshold))),
  predicted_col => 'predicted_leave',
  actual_col => 'actual_leave',
  task_type => 'classification');

SELECT ROUND(precision, 3) AS precision, ROUND(recall, 3) AS recall,
       ROUND(accuracy, 3) AS accuracy, ROUND(f1_score, 3) AS f1_score
FROM ML.EVALUATE(MODEL ml.churn_model,
  (SELECT tenure, MonthlyCharges, Contract, InternetService, PaymentMethod,
          SeniorCitizen, PaperlessBilling, TechSupport, Churn
   FROM ml.telco),
  STRUCT(0.5 AS threshold));

-- Step 4 · Let the costs choose, in SQL
SELECT ROUND(threshold, 2) AS threshold,
       true_positives + false_positives AS offers,
       true_positives AS leavers_caught,
       ROUND(true_positives * (500 / 3 - 50) - false_positives * 50) AS campaign_value
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY campaign_value DESC
LIMIT 5;

-- Step 5 · Ranking: one feature against eight
SELECT 'tenure only' AS model, ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.churn_tenure)
UNION ALL
SELECT 'eight features', ROUND(roc_auc, 3)
FROM ML.EVALUATE(MODEL ml.churn_model);

-- Step 6 · Precision against recall: PR AUC
SELECT ROUND(threshold, 2) AS threshold, ROUND(recall, 3) AS recall,
       ROUND(SAFE_DIVIDE(true_positives, true_positives + false_positives), 3) AS precision
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY recall;
WITH pr AS (
  SELECT threshold, recall,
         SAFE_DIVIDE(true_positives, true_positives + false_positives) AS precision
  FROM ML.ROC_CURVE(MODEL ml.churn_model)
),
steps AS (
  SELECT precision,
         recall - COALESCE(LAG(recall) OVER (ORDER BY threshold DESC), 0) AS recall_gained
  FROM pr
)
SELECT ROUND(SUM(recall_gained * precision), 3) AS pr_auc
FROM steps;

SELECT ROUND(COUNTIF(Churn = 'Yes') / COUNT(*), 3) AS share_who_left
FROM ml.telco;

-- Step 7 · Log loss: are the probabilities honest?
SELECT 'tenure only' AS model, ROUND(log_loss, 3) AS log_loss
FROM ML.EVALUATE(MODEL ml.churn_tenure)
UNION ALL
SELECT 'eight features', ROUND(log_loss, 3)
FROM ML.EVALUATE(MODEL ml.churn_model);

