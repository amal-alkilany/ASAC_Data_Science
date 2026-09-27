# Load retail tables into BigQuery

In this Everyone Do activity, you will create a dataset in your BigQuery project, upload four retail tables, and check what loaded before you write your first SQL query.

**Time:** 45 minutes · **Files:** `Resources/orders.csv`, `Resources/order_items.csv`, `Resources/customers.csv`, `Resources/products.csv`

Follow each step as Tarek shows it. If your screen looks different, post a screenshot in your group channel so a TA can help you.

## Instructions

1. Open `Resources/` beside this README and save the four CSV files to your laptop. On GitHub, open each file and choose **Download raw file**. Keep the original CSVs; do not open and save them in Excel.

2. Open BigQuery. Check that the project shown at the top is your sandbox project.

3. In **Explorer**, open your project's **⋮** menu and choose **Create dataset**. Enter `D03` as the Dataset ID, with a capital D, choose **Multi-region US**, and create it. Dataset names are case-sensitive: `d03` would be a different dataset, and this week's SQL files would not find the tables. Check that it appears under your project.

4. Open the **⋮** menu beside `D03` and choose **Create table**. Set **Create table from** to **Upload** and select `orders.csv`. Name the destination table `orders`, tick **Auto detect**, and set **Header rows to skip** to `1` under Advanced options. Create the table.

5. Open `orders` in Explorer. Read each column name and type in **Schema**. Check that `order_id` is `INTEGER` and `order_date` is `DATE`. In **Details**, check that the table has 5 rows. Open **Preview** to see them without running a query.

6. Upload `products.csv` as `products` with the same settings, then open **Schema**. This file behaves differently. The columns are named `string_field_0`, `string_field_1` and `string_field_2`, not `product_id`, `product_name` and `category`, and nothing went red. Read [Why products.csv is different](#why-productscsv-is-different) below, then fix it:

    1. Delete the table: click it in Explorer, then **⋮** > **Delete**, and type `delete`. You lose nothing; the CSV is still in your Downloads folder.
    2. Choose **Create table** again, with the same source and the same table name, `products`.
    3. Under **Schema**, leave **Auto detect** unticked and switch on **Edit as text**. Type the schema exactly:

        ```text
        product_id:STRING,product_name:STRING,category:STRING
        ```

    4. Under **Advanced options**, keep **Header rows to skip** at `1`. With a typed schema and `0`, the header line loads as a sixth product.
    5. Create the table. Check that **Schema** shows the three names and **Details** shows 5 rows.

7. Upload `order_items.csv` as `order_items` and `customers.csv` as `customers`. Check their Schema and Details tabs too.

8. Compare your four tables with the Check yourself table. In `customers` Preview, find C-455 and look at `city`.

## Check yourself

| Table | Rows | Columns |
|---|---:|---|
| `D03.orders` | 5 | `order_id`, `customer_id`, `order_date`, `status` |
| `D03.order_items` | 12 | `item_id`, `order_id`, `product_id`, `qty`, `price` |
| `D03.customers` | 5 | `customer_id`, `customer_name`, `city`, `segment`, `signup_date` |
| `D03.products` | 5 | `product_id`, `product_name`, `category` |

C-455 has `null` for `city` in Preview. That cell is empty in the CSV, so BigQuery loaded it as `NULL`.

If an upload is still blocking you when the class moves on, follow the next activity on a group-mate's shared screen. Tell your TA which table you still need to load.

## Why products.csv is different

Auto detect reads the first rows of a file, up to 500, and guesses a name and a type for each column. It finds the header row by comparing the first line with the lines below it. In `orders.csv` the first line says `order_id` and the lines below hold numbers such as `1001`, so the first line stands out as names. In `products.csv` every value is text, the header included, so nothing stands out, and BigQuery names the columns `string_field_0`, `string_field_1` and `string_field_2`.

Google's documentation says this directly: "Loading CSV data using schema autodetection does not automatically detect headers if all of the columns are string types. In this case, add a numerical column to the input or declare the schema explicitly." **Edit as text** is how you declare the schema in the console. **Header rows to skip** = `1` still matters: it tells BigQuery the first line is not a product.

The habit to take away: after every upload, open **Schema** and **Details**. An upload can finish without any error and still not be what you wanted.

Sources: Google Cloud, [Loading CSV data from Cloud Storage](https://docs.cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv) (header detection when every column is text) and [Using schema auto-detection](https://docs.cloud.google.com/bigquery/docs/schema-detect) (Auto detect reads up to the first 500 rows). Step 3's capital D: the BigQuery API's [Dataset resource](https://docs.cloud.google.com/bigquery/docs/reference/rest/v2/datasets) says that by default "the dataset and its table names are case-sensitive".

## Hint

Type the schema line exactly: a colon between each name and its type, a comma between columns, no spaces. A slip such as `STRNG` makes **Create table** fail with a message about the schema. If you get `string_field_0` again, **Auto detect** was still ticked.

## Bonus

Open the **Details** tab of `D03.orders`. Find the table's size in bytes and its expiration date. Why does a sandbox table have an expiration date at all?

## References

These are course-owned synthetic retail tables. Their file record is in [`Resources/README.md`](Resources/README.md).
