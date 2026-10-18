# Lab 04 · When the Yes is rare: class weights

In this self-guided lab, you will train a classifier on data where only 16% of the rows are Yes, watch it learn to say No to almost everyone, then fix that with `AUTO_CLASS_WEIGHTS` and `CLASS_WEIGHTS`, and decide whether the result is worth using.

**When:** after class, about 40 minutes, at your own pace. Not submitted. · **Data:** [`employee_data.csv`](../../../../../shared/datasets/ml_classics/employee_data.csv) → `ml.employees` · **SQL:** `Solved/imbalance_and_class_weights.sql`

## How to work through this lab

Run each query, compare with **What you should see**, and answer **Think** in one line. The options are on Google's page [The CREATE MODEL statement for generalized linear models](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-glm).

## The data

1,470 employees of a fictional company created by IBM's data scientists. One row is one employee. The label is `Attrition`: Yes if the employee left. Features: age, gender, distance from home, job level, department, monthly income, performance rating, job satisfaction. `EmployeeID` is an identifier.

Upload `employee_data.csv` as `employees` in the `ml` dataset (**⋮** → **Create table**, Upload, CSV, **Auto detect**).

## Step 1 · How rare is Yes?

```sql
SELECT Attrition, COUNT(*) AS employees,
       ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 3) AS share
FROM ml.employees
GROUP BY Attrition;
```

**What you should see:** 237 Yes (0.161) and 1,233 No (0.839). Saying No for everyone is 83.9% accurate and finds nobody who leaves.

## Step 2 · A model without help

```sql
CREATE OR REPLACE MODEL ml.attrition_plain
OPTIONS (model_type = 'LOGISTIC_REG', input_label_cols = ['Attrition'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2) AS
SELECT Age, Gender, DistanceFromHome, JobLevel, Department, MonthlyIncome,
       PerformanceRating, JobSatisfaction, Attrition
FROM ml.employees;

SELECT ROUND(accuracy, 3) AS accuracy, ROUND(precision, 3) AS precision,
       ROUND(recall, 3) AS recall, ROUND(roc_auc, 3) AS roc_auc
FROM ML.EVALUATE(MODEL ml.attrition_plain);
```

**What you should see:** accuracy about 0.84 and recall close to **0**: the model flags almost nobody. Its accuracy is the majority guess's. Precision may be blank or jump around, because it divides by the handful it flagged.

Why? Training makes the errors on all rows as small as possible. With 84% No, the cheapest way to be right most of the time is to push every probability below 0.5.

**Think:** is this model useless, or is its threshold wrong? Keep the question for step 4.

## Step 3 · `AUTO_CLASS_WEIGHTS`: make the rare class count

```sql
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
```

`AUTO_CLASS_WEIGHTS = TRUE` weights each class by how rare it is, so the 237 Yes count as much in training as the 1,233 No.

**What you should see:** recall about 0.67, precision about 0.25, accuracy about 0.62, and ROC AUC about 0.69, the same as in step 2.

Accuracy went **down** and the model became more useful: it now finds two in three leavers, at the price of many false alarms. ROC AUC did not move: the weights changed where the model draws the line, not how well it ranks employees.

## Step 4 · The threshold does something similar

Back to the plain model, with a lower threshold:

```sql
SELECT ROUND(precision, 3) AS precision, ROUND(recall, 3) AS recall
FROM ML.EVALUATE(MODEL ml.attrition_plain, STRUCT(0.2 AS threshold));
```

**What you should see:** recall jumps from near 0 to roughly half or more. The plain model was not blind; its probabilities were just all low. Class weights and a lower threshold are two routes to the same trade.

**Think:** with step 3's model you could still move the threshold. Why might you prefer class weights to a very low threshold? (Hint: the weighted model's probabilities sit around 0.5 for the rare class.)

## Step 5 · `CLASS_WEIGHTS`: choose the weights yourself

`AUTO_CLASS_WEIGHTS` picks weights from the class sizes. `CLASS_WEIGHTS` lets you say exactly how much each class counts, for example because a missed leaver costs three times a false alarm:

```sql
CREATE OR REPLACE MODEL ml.attrition_custom
OPTIONS (model_type = 'LOGISTIC_REG', input_label_cols = ['Attrition'],
         data_split_method = 'RANDOM', data_split_eval_fraction = 0.2,
         class_weights = [STRUCT('Yes', 3.0), STRUCT('No', 1.0)]) AS
SELECT Age, Gender, DistanceFromHome, JobLevel, Department, MonthlyIncome,
       PerformanceRating, JobSatisfaction, Attrition
FROM ml.employees;

SELECT ROUND(precision, 3) AS precision, ROUND(recall, 3) AS recall
FROM ML.EVALUATE(MODEL ml.attrition_custom);
```

**What you should see:** recall between steps 2 and 3. A weight of 3 helps the Yes class, but less than the automatic weight (about 5 for Yes against 1 for No here, from 1,233 ÷ 237).

If `Attrition` uploaded as BOOLEAN, write `STRUCT(TRUE, 3.0), STRUCT(FALSE, 1.0)`.

## Step 6 · Would you use it?

ROC AUC about 0.69 says the model ranks leavers above stayers more often than chance, but not by much. These eight columns do not hold the strongest reasons people leave (overtime, stock options, years since a promotion are in IBM's full dataset, not in ours).

**Think:** HR wants to use the weighted model to decide who gets a retention interview. Write three sentences: what it would do well, what it would get wrong, and what data you would ask for first.

## What you saw

| Model | Accuracy | Recall | ROC AUC |
|---|---:|---:|---:|
| plain | ≈ 0.84 | ≈ 0 | ≈ 0.69 |
| `AUTO_CLASS_WEIGHTS` | ≈ 0.62 | ≈ 0.67 | ≈ 0.69 |
| `CLASS_WEIGHTS` Yes 3 | | | |
| plain, threshold 0.2 | | | |

## References

IBM HR Analytics Employee Attrition & Performance (fictional data created by IBM data scientists; Kaggle), course copy of ten columns in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md). BigQuery ML: [CREATE MODEL for logistic regression](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-glm), Google Cloud.
