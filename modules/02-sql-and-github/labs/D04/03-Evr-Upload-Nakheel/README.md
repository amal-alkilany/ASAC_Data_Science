# Upload Nakheel Retail

In this activity, you will load the four tables of Nakheel Retail, the business you will work with for most of the programme, into a new dataset.

**Time:** 10 minutes · **Data:** four CSVs in `Resources/` · **Check:** `Resources/check_row_counts.sql`

Nakheel Retail sells clothing and footwear in eight Jordanian cities, in stores and online. The data covers 24 months of orders, September 2024 to August 2026. Read the column list in [`Resources/README.md`](Resources/README.md).

## Instructions

1. Save the four CSVs in `Resources/` to your laptop: `customers.csv`, `products.csv`, `orders.csv`, `order_items.csv`. On GitHub, use **Download raw file** for each. In a zip, the files are already inside the activity folder.
2. Create a dataset `nakheel` in **Multi-region US**.
3. In Explorer, choose **Create table** from the `nakheel` dataset's **⋮** menu. For each CSV, set **Create table from** to **Upload**, select the file, and use its name without `.csv` for the table. Tick **Auto detect** and set **Header rows to skip** to `1` under Advanced options before you create the table. Repeat for `customers`, `products`, `orders` and `order_items`.
4. Open the Schema tab of `orders`. `order_ts` should be `TIMESTAMP` and `delivered_date` `DATE`.
5. Run `Resources/check_row_counts.sql`. It counts all four tables in one result and is available before any solutions are released.

## Check yourself

| Query | Rows returned | One value to check |
|---|---:|---|
| all | 4 | customers 500, products 60, orders 3,000, order_items 7,516 |

If a count is wrong, check the table name and the source file. Delete that table and upload the original CSV from `Resources/` again. If a date column appears as text, check that you used the original CSV without saving it in Excel.

## References

Nakheel Retail, course-owned synthetic data generated 24 September 2026. See [`Resources/README.md`](Resources/README.md).
