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

-- Step 3 · Let the costs choose, in SQL
SELECT ROUND(threshold, 2) AS threshold,
       true_positives + false_positives AS offers,
       true_positives AS leavers_caught,
       ROUND(true_positives * (500 / 3 - 50) - false_positives * 50) AS campaign_value
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY campaign_value DESC
LIMIT 5;

-- Step 4 · Ranking: one feature against eight
SELECT 'tenure only' AS model, ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.churn_tenure)
UNION ALL
SELECT 'eight features', ROUND(roc_auc, 3)
FROM ML.EVALUATE(MODEL ml.churn_model);

-- Step 5 · Log loss: are the probabilities honest?
SELECT 'tenure only' AS model, ROUND(log_loss, 3) AS log_loss
FROM ML.EVALUATE(MODEL ml.churn_tenure)
UNION ALL
SELECT 'eight features', ROUND(log_loss, 3)
FROM ML.EVALUATE(MODEL ml.churn_model);

