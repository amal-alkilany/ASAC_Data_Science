# D15 resources: upload, restart, the fallback file, and where each option is used

## Upload Air Passengers

D15 adds one table, `ml.air_passengers`: 144 months of international airline passengers, January 1949 to December 1960, in thousands.

1. If the `ml` dataset is missing: `CREATE SCHEMA IF NOT EXISTS ml OPTIONS (location = 'US');`
2. Download [`air_passengers.csv`](../../../../../shared/datasets/ml_classics/air_passengers.csv).
3. Next to `ml`, **⋮** → **Create table**. **Create table from:** Upload; choose the file; **File format:** CSV; **Table:** `air_passengers`; tick **Auto detect**; **Create table**.
4. Open the table's **Schema** tab: `month` must be DATE and `passengers` INTEGER. If `month` shows STRING, delete the table and upload again with the schema set by hand.

Check: `SELECT COUNT(*) AS months, MIN(month) AS first_month, MAX(month) AS last_month FROM ml.air_passengers;` returns 144, 1949-01-01 and 1960-12-01.

## Start again from the uploaded tables

[`restart_d15.sql`](restart_d15.sql) rebuilds everything the day's activities and labs build on:

| Part | Needs | Rebuilds |
|---|---|---|
| A | `ml.air_passengers` | the views `ml.air_training`, `ml.air_validation`, `ml.air_test`; the models `ml.air_arima` (120 months) and `ml.air_arima_final` (132 months) |
| B | `ml.insurance` (D11) | the view `ml.insurance_groups`; the models `ml.ins_transform`, `ml.ins_boosted` and `ml.ins_explain` |

Run it one statement at a time. The two boosted-trees models are *external* models: they train in the sandbox but slowly (10 to 15 minutes or more each); everything else is built-in and trains quickly.

## If tree models will not train: the fallback file

Activity 07 explains D14's boosted-trees model. If `ml.ins_boosted` will not train in your sandbox, download [`fallback/d15_insurance_explain.csv`](fallback/d15_insurance_explain.csv) and upload it as `d15_explain` in `ml` (**Auto detect**).

One row is one of activity 07's five people (A to E): `person_id` (their place in the order by charges), `person`, `split`, the six features, `charges`, the model's `prediction`, its `baseline`, and one contribution per feature (`contrib_age`, `contrib_bmi`, `contrib_children`, `contrib_sex`, `contrib_smoker`, `contrib_region`). The values were computed outside BigQuery with XGBoost and BigQuery's default settings, the same settings as `ml.ins_boosted`; BigQuery's own attributions may differ a little.

The pieces add up to each prediction:

```sql
SELECT person, prediction, baseline, contrib_smoker, contrib_age, contrib_bmi,
       ROUND(baseline + contrib_age + contrib_bmi + contrib_children
             + contrib_sex + contrib_smoker + contrib_region, 2) AS rebuilt
FROM ml.d15_explain
ORDER BY person;
```

**What you should see:** five rows, `rebuilt` equal to `prediction` on each. E has the highest prediction, about 43,526, from a baseline of about 13,219, with smoking adding about 21,546. Activity 07, step 5, turns the six contribution columns into one row per person and feature. The global importance in activity 07, step 3, was computed the same way, as the average size of each contribution over the 268 validation people; its values are printed in that step.

`ml.ins_transform` (activity 08) and every ARIMA_PLUS model are built-in, so the rest of the day does not need a fallback.

## Every ARIMA_PLUS option, and where it is used

From Google's CREATE MODEL page for ARIMA_PLUS (updated 16 October 2026), in the page's order.

| Option | Default | Where |
|---|---|---|
| `MODEL_TYPE` | none (required) | activity 02, step 2; lab 09, steps 2 and 4 |
| `TIME_SERIES_TIMESTAMP_COL` | none | activity 02, step 2; lab 09, step 4 |
| `TIME_SERIES_DATA_COL` | none | activity 02, step 2; lab 09, step 4 |
| `TIME_SERIES_ID_COL` | none | lab 09, step 17 |
| `HORIZON` | 1,000 | activity 02, step 2; lab 09, step 5 |
| `AUTO_ARIMA` | TRUE | lab 09, steps 2 and 7 |
| `AUTO_ARIMA_MAX_ORDER` | 2 | lab 09, step 6 |
| `AUTO_ARIMA_MIN_ORDER` | 0 | lab 09, step 6 |
| `NON_SEASONAL_ORDER` | none | lab 09, step 7 |
| `DATA_FREQUENCY` | `AUTO_FREQUENCY` | lab 09, step 8; lab 13, step 6 |
| `INCLUDE_DRIFT` | FALSE | lab 09, step 7 |
| `HOLIDAY_REGION` | none | lab 09, step 16; lab 13, step 6 (Jordan is not on the list) |
| `CLEAN_SPIKES_AND_DIPS` | TRUE | activity 04, step 4; lab 09, step 10 |
| `ADJUST_STEP_CHANGES` | TRUE | lab 09, step 10 |
| `TIME_SERIES_LENGTH_FRACTION` | all points | lab 09, step 13 |
| `MIN_TIME_SERIES_LENGTH` | 20 | lab 09, step 13 |
| `MAX_TIME_SERIES_LENGTH` | none | lab 09, step 13 |
| `TREND_SMOOTHING_WINDOW_SIZE` | none | lab 09, step 12 |
| `DECOMPOSE_TIME_SERIES` | TRUE | lab 09, step 11 |
| `FORECAST_LIMIT_LOWER_BOUND` | none | lab 09, step 14; lab 13, step 9 |
| `FORECAST_LIMIT_UPPER_BOUND` | none | lab 09, step 14 |
| `SEASONALITIES` | `AUTO` | lab 09, step 9 |
| `HIERARCHICAL_TIME_SERIES_COLS` | none | lab 09, step 18 (read, not run) |
| `KMS_KEY_NAME` | none | lab 09, step 18 (not used in this course) |
| `custom_holiday` (in the `AS` part) | | lab 13, step 8 |

## Every function that reads an ARIMA_PLUS model

| Function | Arguments (default) | Where |
|---|---|---|
| `ML.FORECAST` | `horizon` (3), `confidence_level` (0.95) | activities 02, 04, 06, 08; lab 10, steps 1 to 4 |
| `ML.EXPLAIN_FORECAST` | `horizon` (3), `confidence_level` (0.95) | activity 04, step 4; lab 10, steps 5 and 6; lab 09, steps 10 to 12 |
| `ML.DETECT_ANOMALIES` | `anomaly_prob_threshold` (0.95); new data, optional | lab 10, steps 7 to 9 (billed even in a sandbox) |
| `ML.ARIMA_EVALUATE` | `show_all_candidate_models` (TRUE for one series) | lab 09, steps 3 and 6; lab 10, step 10; lab 13, step 6 |
| `ML.ARIMA_COEFFICIENTS` | none | lab 10, step 11 |
| `ML.EVALUATE` (time series) | input data; `perform_aggregation` (TRUE), `horizon`, `confidence_level` (0.95) | lab 10, steps 12 and 13 |
| `ML.METRICS` (Preview; needs no model) | a table or query; `predicted_col`, `actual_col`, `task_type` (`'regression'` or `'classification'`), no defaults | lab 10, step 14 |

## Every explain and transform function, and where it is used

| Function or option | Arguments (default) | Where |
|---|---|---|
| `ML.EXPLAIN_PREDICT` | `top_k_features` (5) | activity 07, steps 1 and 2; lab 11, step 2 |
| | `threshold` (0.5) | lab 11, step 6 |
| | `approx_feature_contrib` (FALSE) | lab 11, step 4 |
| | `max_output_tokens` (not described on the page) | lab 11, step 5 |
| | output columns | lab 11, step 3 |
| `ML.GLOBAL_EXPLAIN` | `class_level_explain` (FALSE) | activity 07, step 3; lab 11, steps 7 and 8 |
| `ENABLE_GLOBAL_EXPLAIN` (boosted trees option) | FALSE | activity 07, step 3; lab 11, steps 7 and 8 |
| `APPROX_GLOBAL_FEATURE_CONTRIB` (boosted trees option) | see lab 11 | lab 11, step 11 |
| `ML.FEATURE_IMPORTANCE` | none | activity 07, step 3; lab 11, step 10 |
| `TRANSFORM` clause | | activity 08, step 1; lab 12, steps 3 to 10 |
| `ML.TRANSFORM` | | lab 12, steps 3, 6 and 7 |
| `ML.FEATURE_INFO` | none (the model only); reports the columns before `TRANSFORM` | lab 12, step 10 |
| `ML.PREDICT` | | activity 08, step 3 |
| `ML.QUANTILE_BUCKETIZE` | `num_buckets`, `output_format` (`'bucket_names'`) | activity 08, step 1; lab 12, steps 2 to 4 |
| `ML.BUCKETIZE` | `array_split_points`, `exclude_boundaries` (FALSE), `output_format` | lab 12, step 5 |
| `ML.STANDARD_SCALER`, `ML.MIN_MAX_SCALER`, `ML.MAX_ABS_SCALER`, `ML.ROBUST_SCALER` | | lab 12, step 6 |
| `ML.FEATURE_CROSS`, `ML.POLYNOMIAL_EXPAND` | | lab 12, step 7 |
| `ML.IMPUTER`, `ML.NORMALIZER`, `ML.HASH_BUCKETIZE`, `ML.LABEL_ENCODER`, `ML.MULTI_HOT_ENCODER`, `ML.ONE_HOT_ENCODER`, `ML.NGRAMS`, `ML.BAG_OF_WORDS`, `ML.TF_IDF` | | lab 12, step 8 (named, not run) |

## Contribution analysis (lab 14, optional), and where each option is used

From Google's CREATE MODEL page for contribution analysis models (updated 13 October 2026). It is a model type, read with `ML.GET_INSIGHTS`; there is no function called ML.CONTRIBUTION_ANALYSIS.

| Option or function | Default | Where |
|---|---|---|
| `MODEL_TYPE = 'CONTRIBUTION_ANALYSIS'` | none (required) | lab 14, step 3 |
| `CONTRIBUTION_METRIC`: `SUM(…)` | none | lab 14, step 3 |
| `CONTRIBUTION_METRIC`: `SUM(…)/SUM(…)` | | lab 14, step 11 |
| `CONTRIBUTION_METRIC`: `SUM(…)/COUNT(DISTINCT …)` | | lab 14, step 12 |
| `IS_TEST_COL` (a BOOL column) | none | lab 14, steps 2 and 3 |
| `DIMENSION_ID_COLS` | every other column | lab 14, steps 3 and 7 |
| `MIN_APRIORI_SUPPORT` | 0.1 | lab 14, step 8 |
| `TOP_K_INSIGHTS_BY_APRIORI_SUPPORT` | none | lab 14, step 9 |
| `PRUNING_METHOD` | `'NO_PRUNING'` | lab 14, step 10 |
| `ML.GET_INSIGHTS` | none (the model only) | lab 14, steps 4 to 12 |

## Tables D15 writes for Power BI

| Table | One row is one … | Written by |
|---|---|---|
| `ml.air_forecast` | month of 1960: forecast, 95% bounds, actual | activity 08, step 2 |
| `ml.insurance_scored` | insured person, with `split` and `predicted_charges` | activity 08, step 3 |
| `ml.revenue_forecast` | day: Nakheel's forecast revenue for 30 days | lab 13, step 9 (optional) |

None shares its name with one of its columns. Power BI connects to them on D22.

## Links

- [CREATE MODEL for ARIMA_PLUS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-time-series), [ML.FORECAST](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-forecast), [ML.EXPLAIN_FORECAST](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-explain-forecast), [ML.DETECT_ANOMALIES](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-detect-anomalies), [ML.ARIMA_EVALUATE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-arima-evaluate), [ML.ARIMA_COEFFICIENTS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-arima-coefficients), [ML.EVALUATE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-evaluate), Google Cloud.
- [ML.EXPLAIN_PREDICT](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-explain-predict), [ML.GLOBAL_EXPLAIN](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-global-explain), [ML.FEATURE_IMPORTANCE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-importance), [Explainable AI overview](https://docs.cloud.google.com/bigquery/docs/xai-overview), Google Cloud.
- [The TRANSFORM clause](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create#transform), [manual preprocessing](https://docs.cloud.google.com/bigquery/docs/manual-preprocessing), [ML.QUANTILE_BUCKETIZE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-quantile-bucketize), [ML.BUCKETIZE](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-bucketize), Google Cloud.
- [ML.METRICS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-metrics) (Preview), [ML.FEATURE_INFO](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-feature), [CREATE MODEL for contribution analysis](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-contribution-analysis), [ML.GET_INSIGHTS](https://docs.cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-get-insights), Google Cloud.
- [BigQuery ML pricing](https://cloud.google.com/bigquery/pricing#bqml): built-in and external models, and the cost of the ARIMA search.
- Air Passengers: Box, Jenkins and Reinsel, *Time Series Analysis, Forecasting and Control* (1976), Series G, as listed on the [R datasets page](https://rweb.stat.umn.edu/R/library/datasets/html/AirPassengers.html); course copy in [`shared/datasets/ml_classics`](../../../../../shared/datasets/ml_classics/README.md).
- The module's [reference links](../../../resources/bigquery-ml-reference-links.md).
