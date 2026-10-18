# Classic machine-learning datasets

Small, clean teaching datasets for Module 3. One row is already one example, so the SQL stays short and the attention goes to the model. Each file is uploaded to the `ml` dataset in BigQuery.

| File | Table in BigQuery | One row is one … | Rows | Used on |
|---|---|---|---:|---|
| [`salary_data.csv`](salary_data.csv) | `ml.salary_data` | past hire | 30 | D11: a first model, one feature |
| [`insurance.csv`](insurance.csv) | `ml.insurance` | insured person | 1,338 | D11: many features, scored on held-out rows |
| [`mpg.csv`](mpg.csv) | `ml.cars` | car model | 398 | D11 lab (self-guided) |
| [`telco_churn.csv`](telco_churn.csv) | `ml.telco` | telecom customer | 7,043 | D12: predicting a category |
| [`employee_data.csv`](employee_data.csv) | `ml.employees` | employee | 1,470 | D12 lab 04: a rare Yes |
| [`mall_customers.csv`](mall_customers.csv) | `ml.mall` | mall card member | 200 | D13: a first clustering, judging it, labs 05–06 |
| [`penguins.csv`](penguins.csv) | none: class reads `bigquery-public-data.ml_datasets.penguins` | penguin | 344 | D13 activity 03 and D12 lab 05 (reference copy) |
| [`wholesale_customers.csv`](wholesale_customers.csv) | `ml.wholesale` | client of a food wholesaler | 440 | D13 labs 07–08: heavy tails, cosine distance, anomalies |

## Upload to BigQuery

1. Create the dataset once (D11 activity 02 does it in SQL): `CREATE SCHEMA IF NOT EXISTS ml OPTIONS (location = 'US');`
2. Download the CSV file from this folder.
3. Next to `ml`, **⋮** → **Create table**. **Create table from:** Upload; choose the file; **File format:** CSV. **Table:** the name in the table above. **Schema:** tick **Auto detect**. **Create table**.

Use the table names above. None of them is also the name of one of its columns: in BigQuery a table name can stand for the whole row, so `salary` as a table holding a `salary` column invites confusion. That is why the salary table is `salary_data`.

The steps are the same as in [Upload a CSV to BigQuery](../../../modules/02-sql/resources/upload-a-csv-to-bigquery.md).

## Check the upload

| Table | `COUNT(*)` | Check |
|---|---:|---|
| `ml.salary_data` | 30 | `years_experience` from 1.1 to 10.5 |
| `ml.insurance` | 1,338 | `smoker` and `sex` are text (STRING) |
| `ml.cars` | 398 | `horsepower` arrives as STRING: six cars have `?` (the lab explains why that matters) |
| `ml.telco` | 7,043 | `TotalCharges` arrives as STRING (11 blanks, all tenure 0); `Churn` is Yes or No |
| `ml.employees` | 1,470 | `Attrition` is Yes or No |
| `ml.mall` | 200 | `annual_income_k` 15 to 137 · `spending_score` 1 to 99 · `gender` is text |
| `ml.wholesale` | 440 | `channel` Horeca (298) or Retail (142) · `region` Lisbon, Oporto or Other · six spending columns, whole numbers |

## Sources

| File | Original dataset | Public page | Licence |
|---|---|---|---|
| `salary_data.csv` | Salary data for simple linear regression, the 30-row teaching set from the *Machine Learning A–Z* course, widely shared on Kaggle. Columns renamed to `years_experience` and `salary`; US dollars | [Kaggle](https://www.kaggle.com/datasets/karthickveerakumar/salary-data-simple-linear-regression) | To confirm on the Kaggle page |
| `insurance.csv` | Medical Cost Personal Datasets, from Brett Lantz, *Machine Learning with R* (Packt, 2013); simulated from US demographic statistics. Yearly medical charges in US dollars. Course copy from the book's public data repository, [`stedy/Machine-Learning-with-R-datasets`](https://github.com/stedy/Machine-Learning-with-R-datasets) | [Kaggle](https://www.kaggle.com/datasets/mirichoi0218/insurance) | To confirm on the Kaggle page (the book repository states its datasets are public domain) |
| `mpg.csv` | Auto MPG (Quinlan, 1993), UCI Machine Learning Repository, [doi:10.24432/C5859H](https://doi.org/10.24432/C5859H). Six of the original columns. Miles per gallon: 10 mpg is about 4.3 km per litre | [UCI](https://archive.ics.uci.edu/dataset/9/auto+mpg) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| `telco_churn.csv` | Telco Customer Churn, IBM sample data (7,043 customers). Course copy from `data/Telco-Customer-Churn.csv` in IBM's repository | [IBM on GitHub](https://github.com/IBM/telco-customer-churn-on-icp4d) · [Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) | IBM's repository is Apache 2.0; it gives no separate terms for the data |
| `employee_data.csv` | IBM HR Analytics Employee Attrition & Performance, fictional data created by IBM data scientists. Ten of the columns; `EmployeeID` added for the course copy | [Kaggle](https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset) | To confirm on the Kaggle page |
| `mall_customers.csv` | Mall Customer Segmentation Data: 200 members of a mall's card scheme with age, gender, yearly income (thousands of dollars) and a spending score from 1 to 100 that the mall assigns from purchase behaviour. Made for teaching, from the *Machine Learning A–Z* course. Columns renamed (`customer_id`, `gender`, `age`, `annual_income_k`, `spending_score`); values unchanged. Course copy from a public GitHub mirror, checked value by value against a second mirror | [Kaggle](https://www.kaggle.com/datasets/vjchoudhary7/customer-segmentation-tutorial-in-python) | Kaggle lists "Other (specified in description)"; the description says it was made for learning and gives no licence. To confirm |
| `penguins.csv` | Palmer penguins (Gorman, Williams and Fraser, 2014, *PLoS ONE* 9(3): e90081), from `penguins_raw` in the palmerpenguins package, with the column names and species names of BigQuery's public table (`culmen_length_mm`, `Adelie Penguin (Pygoscelis adeliae)`, `MALE`/`FEMALE`). For reference: class reads the public table | [palmerpenguins](https://allisonhorst.github.io/palmerpenguins/) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `wholesale_customers.csv` | Wholesale customers (Cardoso, 2013), UCI Machine Learning Repository, [doi:10.24432/C5030X](https://doi.org/10.24432/C5030X): 440 clients of a Portuguese food distributor and a year's spending, in monetary units, on six product groups. `client_id` added; channel and region codes written out (1 Horeca, 2 Retail; 1 Lisbon, 2 Oporto, 3 Other); columns renamed in lower case (`Delicassen` → `delicatessen`). Course copy checked against the means, minimums and maximums on the UCI page | [UCI](https://archive.ics.uci.edu/dataset/292/wholesale+customers) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |

D12 lab 05 and D13 activity 03 use the Palmer penguins, which BigQuery hosts as the public table `bigquery-public-data.ml_datasets.penguins`, so nothing is uploaded; `penguins.csv` is a fixed copy for checking numbers. Source: [palmerpenguins](https://allisonhorst.github.io/palmerpenguins/) (Horst, Hill and Gorman, 2020), data from Gorman, Williams and Fraser (2014), *PLoS ONE* 9(3): e90081; [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

Course copies taken 18 October 2026 from Tarek's TechCatalyst materials, the book repository, IBM's repository, the palmerpenguins repository and public mirrors of the Mall and UCI files. Licences of the Kaggle copies to be confirmed before the folder is published on GitHub.
