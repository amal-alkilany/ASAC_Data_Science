# Lab 03 · Thresholds and curves: from a probability to a decision

In this self-guided lab, you will read the whole ROC curve, rebuild the confusion matrix at any threshold, let SQL find the threshold your costs prefer, and compare a one-feature model with the eight-feature one on ranking.

**When:** after class, about 40 minutes, at your own pace. Not submitted. · **Data:** `ml.telco`, `ml.churn_tenure`, `ml.churn_model` (activities 01 and 02) · **SQL:** `Solved/thresholds_and_curves.sql`

## How to work through this lab

Run each query, compare with **What you should see**, and answer **Think** in one line. If the models are missing, run activity 01 block 3 and activity 02 block 1.

## Step 1 · The whole ROC curve

```sql
SELECT ROUND(threshold, 3) AS threshold,
       true_positives, false_positives, false_negatives, true_negatives,
       ROUND(recall, 3) AS recall, ROUND(false_positive_rate, 3) AS false_positive_rate
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY threshold;
```

**What you should see:** about a hundred rows. Each row is one threshold and its four counts on the rows held aside. Near threshold 0, almost every customer is flagged: recall near 1, and almost every stayer flagged too. Near 1, almost nobody is flagged.

**Think:** which row would the retention team pick if offers were free? And if they could only make 100?

## Step 2 · The confusion matrix at any threshold

```sql
SELECT * FROM ML.CONFUSION_MATRIX(MODEL ml.churn_model, STRUCT(0.3 AS threshold));
SELECT * FROM ML.CONFUSION_MATRIX(MODEL ml.churn_model, STRUCT(0.7 AS threshold));
```

**What you should see:** at 0.3 the "Yes" column grows: more leavers caught, more stayers flagged. At 0.7 it shrinks. The model is the same; only the cut moved.

The same setting works in `ML.PREDICT`: `ML.PREDICT(MODEL ml.churn_model, (SELECT …), STRUCT(0.3 AS threshold))` changes `predicted_Churn`, not the probabilities.

## Step 3 · Let the costs choose, in SQL

Class used invented costs: an offer 50; a lost customer 500; an offer keeps 1 in 3 of the leavers who get it. A caught leaver is worth about 500 ÷ 3 − 50; a wasted offer costs 50. Price every threshold at once:

```sql
SELECT ROUND(threshold, 2) AS threshold,
       true_positives + false_positives AS offers,
       true_positives AS leavers_caught,
       ROUND(true_positives * (500 / 3 - 50) - false_positives * 50) AS campaign_value
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY campaign_value DESC
LIMIT 5;
```

**What you should see:** the best thresholds sit around 0.3. Now change 50 to 100 in both places and run it again.

**What you should see:** the best threshold moves up, to about 0.6. Costlier offers should go only to customers more likely to leave.

**Think:** who in a company should supply these costs: the analyst, or the business?

## Step 4 · Ranking: one feature against eight

ROC AUC does not depend on the threshold. It answers: if you pick one leaver and one stayer at random, how often does the model give the leaver the higher probability?

```sql
SELECT 'tenure only' AS model, ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.churn_tenure)
UNION ALL
SELECT 'eight features', ROUND(roc_auc, 3)
FROM ML.EVALUATE(MODEL ml.churn_model);
```

**What you should see:** about 0.74 against about 0.84. The extra features help the model put leavers above stayers.

## Step 5 · Log loss: are the probabilities honest?

`ML.EVALUATE` also prints `log_loss`. It punishes confident mistakes: a leaver given 0.02 costs far more than a leaver given 0.4. Lower is better.

```sql
SELECT 'tenure only' AS model, ROUND(log_loss, 3) AS log_loss
FROM ML.EVALUATE(MODEL ml.churn_tenure)
UNION ALL
SELECT 'eight features', ROUND(log_loss, 3)
FROM ML.EVALUATE(MODEL ml.churn_model);
```

**What you should see:** the eight-feature model's log loss is lower. Accuracy and precision look only at the Yes or No; log loss looks at the probabilities themselves.

**Think:** when would you care more about honest probabilities than about the Yes or No? (Hint: step 3 multiplies probabilities by money.)

## What you saw

| Tool | What it showed |
|---|---|
| `ML.ROC_CURVE` | |
| `STRUCT(0.3 AS threshold)` | |
| campaign value per threshold | |
| `roc_auc`, one feature against eight | |
| `log_loss` | |

## References

Telco Customer Churn, IBM sample data. BigQuery ML: [ML.ROC_CURVE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-roc), [ML.CONFUSION_MATRIX](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-confusion), [ML.EVALUATE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-evaluate), Google Cloud.
