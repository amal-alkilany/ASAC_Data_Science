# Lab 03 · Thresholds and curves: from a probability to a decision

In this self-guided lab, you will read the whole ROC curve, rebuild the confusion matrix at any threshold, let SQL find the threshold your costs prefer, compare a one-feature model with the eight-feature one on ranking, and compute the precision-recall curve and its area (PR AUC) from BigQuery's output.

**When:** after class, about 50 minutes, at your own pace. Not submitted. · **Data:** `ml.telco`, `ml.churn_tenure`, `ml.churn_model` (activities 01 and 02) · **SQL:** `Solved/thresholds_and_curves.sql`

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

## Step 5 · Precision against recall: PR AUC

ROC AUC asks whether leavers get higher probabilities than stayers; guessing scores 0.5 whatever the share of leavers. The precision-recall curve asks something closer to the retention team's question: of the customers we flag, how many really leave, as we flag more and find more leavers? Guessing scores the share who left. BigQuery does not print PR AUC, but `ML.ROC_CURVE` has everything needed: precision is `true_positives ÷ (true_positives + false_positives)`.

```sql
SELECT ROUND(threshold, 2) AS threshold, ROUND(recall, 3) AS recall,
       ROUND(SAFE_DIVIDE(true_positives, true_positives + false_positives), 3) AS precision
FROM ML.ROC_CURVE(MODEL ml.churn_model)
ORDER BY recall;
```

**What you should see:** as recall rises toward 1, precision falls toward about 0.27: flag everyone and only the share who left are right.

Now the area under that curve. Walk the thresholds from high to low; each step finds a little more recall, and that slice counts at the precision it came with. `LAG` (D10's window functions) gives the recall of the step before.

```sql
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
```

**What you should see:** PR AUC about 0.64 (between about 0.60 and 0.67, depending on your split), against a guessing line of 0.265. Change `ml.churn_model` to `ml.churn_tenure` in the first query: about 0.49. `ML.ROC_CURVE` uses about a hundred thresholds, so this is a close approximation of the area Python's `average_precision_score` gives, not the exact value.

**Think:** ROC AUC 0.84 and PR AUC 0.63 describe the same model. Why is it wrong to say the second is "worse"? (Hint: compare each with its own guessing line.)

## Step 6 · Log loss: are the probabilities honest?

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
| PR AUC, and its guessing line | |
| `log_loss` | |

## References

Telco Customer Churn, IBM sample data. Precision-recall curves: Saito and Rehmsmeier, "The precision-recall plot is more informative than the ROC plot when evaluating binary classifiers on imbalanced datasets", *PLoS ONE*, 2015. BigQuery ML: [ML.ROC_CURVE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-roc), [ML.CONFUSION_MATRIX](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-confusion), [ML.EVALUATE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-evaluate), Google Cloud.
