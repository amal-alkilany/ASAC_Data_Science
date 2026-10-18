# D12 resources

## The data

| File | Table | Used in |
|---|---|---|
| [`telco_churn.csv`](../../../../../shared/datasets/ml_classics/telco_churn.csv) | `ml.telco` | activities 01 and 02, lab 03 |
| [`employee_data.csv`](../../../../../shared/datasets/ml_classics/employee_data.csv) | `ml.employees` | lab 04 |
| `bigquery-public-data.ml_datasets.penguins` | public table, no upload | lab 05 |
| Nakheel `orders` and `customers` (D04), view `ml.customer_features` (D11 lab 08) | | lab 06 (optional) |

Sources and upload steps: [`shared/datasets/ml_classics/README.md`](../../../../../shared/datasets/ml_classics/README.md).

## The order of the after-class labs

Lab 03 reads the models from activities 01 and 02. Labs 04 and 05 stand alone. Lab 06 is optional self-study and needs D11's lab 08 view first.

## If something goes wrong

- **`Churn` or `Attrition` uploaded as BOOLEAN:** write `TRUE`/`FALSE` for `'Yes'`/`'No'`, including in `p.label = 'Yes'` and in `CLASS_WEIGHTS`.
- **`Not found: Dataset bigquery-public-data:ml_datasets`** in lab 05: your `ml` dataset is not in the US location. Create it with `OPTIONS (location = 'US')`.
- **Your scores differ from a classmate's:** every `RANDOM` split holds aside different rows.
- **Precision is empty:** the model said Yes for nobody at that threshold; precision divides by zero flagged rows.
