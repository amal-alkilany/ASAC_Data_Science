-- D12 · 02 · Eight features, judged honestly, and priced · Starter
-- Run one numbered block at a time. CREATE MODEL and the ML. functions run in BigQuery only.
-- If Churn uploaded as BOOLEAN, write TRUE/FALSE for 'Yes'/'No'.

-- 1. Eight features, 20% held aside.
CREATE OR REPLACE MODEL ml.churn_model
OPTIONS (
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['Churn'],
  data_split_method = 'RANDOM',
  data_split_eval_fraction = 0.2
) AS
SELECT tenure, MonthlyCharges, Contract, InternetService,
       PaymentMethod, SeniorCitizen, PaperlessBilling, TechSupport,
       Churn
FROM ml.telco;

-- 2. Five scores on the 20% held aside, at threshold 0.5.
SELECT ROUND(accuracy, 3) AS accuracy, ROUND(precision, 3) AS precision,
       ROUND(recall, 3) AS recall, ROUND(f1_score, 3) AS f1,
       ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.churn_model);

-- 3. The majority guess: say No for everyone.
SELECT ROUND(COUNTIF(Churn = 'No') / COUNT(*), 3) AS majority_accuracy
FROM ml.telco;

-- 4. The confusion matrix of the held-aside rows.
SELECT *
FROM ML.CONFUSION_MATRIX(MODEL ml.churn_model);

-- 5. The ROC curve: one row per threshold.
SELECT ROUND(threshold, 2) AS threshold, ROUND(recall, 3) AS recall,
       ROUND(false_positive_rate, 3) AS false_positive_rate
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY threshold;

-- 6. Three thresholds.
SELECT '0.3' AS threshold, ROUND(precision, 2) AS precision, ROUND(recall, 2) AS recall
FROM ML.EVALUATE(MODEL ml.churn_model, STRUCT(0.3 AS threshold))
UNION ALL
SELECT '0.5', ROUND(precision, 2), ROUND(recall, 2)
FROM ML.EVALUATE(MODEL ml.churn_model, STRUCT(0.5 AS threshold))
UNION ALL
SELECT '0.7', ROUND(precision, 2), ROUND(recall, 2)
FROM ML.EVALUATE(MODEL ml.churn_model, STRUCT(0.7 AS threshold));

-- 7. The leavers it said would stay, by contract.
SELECT Contract, COUNT(*) AS missed_leavers,
       ROUND(AVG(tenure), 1) AS avg_tenure
FROM ML.PREDICT(MODEL ml.churn_model, (SELECT * FROM ml.telco))
WHERE Churn = 'Yes' AND predicted_Churn = 'No'
GROUP BY Contract;

-- 8. What it learned: read the signs.
SELECT processed_input, ROUND(weight, 3) AS weight, category_weights
FROM ML.WEIGHTS(MODEL ml.churn_model);

-- 9. The same customer, two contracts.
SELECT Contract, ROUND(p.prob, 2) AS prob_leave
FROM ML.PREDICT(MODEL ml.churn_model,
  (SELECT 12 AS tenure, 70.0 AS MonthlyCharges, 'Month-to-month' AS Contract,
          'Fiber optic' AS InternetService, 'Electronic check' AS PaymentMethod,
          0 AS SeniorCitizen, 'Yes' AS PaperlessBilling, 'No' AS TechSupport
   UNION ALL
   SELECT 12, 70.0, 'Two year', 'Fiber optic', 'Electronic check', 0, 'Yes', 'No')),
  UNNEST(predicted_Churn_probs) AS p
WHERE p.label = 'Yes';
