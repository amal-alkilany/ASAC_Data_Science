-- D15 · Restart: rebuild today's views and models from the uploaded tables
-- Run the part you need, one statement at a time, top to bottom.
-- Part A needs ml.air_passengers (upload air_passengers.csv: see Resources/README.md).
-- Part B needs ml.insurance (D11; upload insurance.csv the same way).
-- Nothing here reads a saved table from class; the tables ml.air_forecast and
-- ml.insurance_scored are written by activity 08 once these exist.

CREATE SCHEMA IF NOT EXISTS ml OPTIONS (location = 'US');

-- Part A · Air Passengers --------------------------------------------------

-- Check the upload: 144 months, 1949-01-01 to 1960-12-01.
SELECT COUNT(*) AS months, MIN(month) AS first_month, MAX(month) AS last_month
FROM ml.air_passengers;

-- The three groups, by date (activities 02 and 03).
CREATE OR REPLACE VIEW ml.air_training AS
SELECT month, passengers
FROM ml.air_passengers
WHERE month < '1959-01-01';

CREATE OR REPLACE VIEW ml.air_validation AS
SELECT month, passengers FROM ml.air_passengers
WHERE month >= '1959-01-01' AND month < '1960-01-01';

CREATE OR REPLACE VIEW ml.air_test AS
SELECT month, passengers FROM ml.air_passengers
WHERE month >= '1960-01-01';

-- Check: training 120, validation 12, test 12.
SELECT 'training' AS air_group, COUNT(*) AS months FROM ml.air_training
UNION ALL
SELECT 'validation', COUNT(*) FROM ml.air_validation
UNION ALL
SELECT 'test', COUNT(*) FROM ml.air_test;

-- The class model, trained on the 120 training months (activity 02).
CREATE OR REPLACE MODEL ml.air_arima
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12) AS
SELECT month, passengers FROM ml.air_training;

-- The final model, trained on the 132 months before the test (activity 06).
CREATE OR REPLACE MODEL ml.air_arima_final
OPTIONS (MODEL_TYPE = 'ARIMA_PLUS',
         TIME_SERIES_TIMESTAMP_COL = 'month',
         TIME_SERIES_DATA_COL = 'passengers',
         HORIZON = 12) AS
SELECT month, passengers FROM ml.air_passengers
WHERE month < '1960-01-01';

-- Part B · Insurance -------------------------------------------------------

-- Check the upload: 1,338 people.
SELECT COUNT(*) AS people FROM ml.insurance;

-- The fixed groups from D14 activity 01: 803 training, 268 validation, 267 test.
CREATE OR REPLACE VIEW ml.insurance_groups AS
SELECT *,
       CASE MOD(ROW_NUMBER() OVER (ORDER BY charges), 5)
         WHEN 3 THEN 'validation'
         WHEN 4 THEN 'test'
         ELSE 'train'
       END AS split
FROM ml.insurance;

SELECT split, COUNT(*) AS people
FROM ml.insurance_groups
GROUP BY split
ORDER BY people DESC;

-- The TRANSFORM model from activity 08 (linear: trains in every sandbox).
CREATE OR REPLACE MODEL ml.ins_transform
TRANSFORM (ML.QUANTILE_BUCKETIZE(bmi, 4) OVER () AS bmi_band,
           age, sex, children, smoker, region, charges)
OPTIONS (model_type = 'LINEAR_REG',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

-- The two boosted-trees models (D14 activity 01 and activity 07). Boosted trees are external models,
-- billed separately; if these stop with a billing message, use the fallback file instead (Resources/README.md).
CREATE OR REPLACE MODEL ml.ins_boosted
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT') AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';

CREATE OR REPLACE MODEL ml.ins_explain
OPTIONS (model_type = 'BOOSTED_TREE_REGRESSOR',
         input_label_cols = ['charges'],
         data_split_method = 'NO_SPLIT',
         enable_global_explain = TRUE) AS
SELECT age, sex, bmi, children, smoker, region, charges
FROM ml.insurance_groups
WHERE split = 'train';
