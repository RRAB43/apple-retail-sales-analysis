# Data

The five CSVs (`sales`, `products`, `stores`, `category`, `warranty` — 1,040,191 sales rows total) are **not committed** to this repo: they are distributed by the original project author and are too large for a clean git history.

**Get them:** [Zero Analyst's Apple Retail Sales SQL Project](https://github.com/najirh/Apple-Retail-Sales-SQL-Project---Analyzing-Millions-of-Sales-Rows) — the README there links the dataset download.

**Load them (PostgreSQL):**

```sql
CREATE TABLE category (category_id VARCHAR PRIMARY KEY, category_name VARCHAR);
CREATE TABLE products (product_id VARCHAR PRIMARY KEY, product_name VARCHAR,
                       category_id VARCHAR REFERENCES category, launch_date DATE, price NUMERIC);
CREATE TABLE stores   (store_id VARCHAR PRIMARY KEY, store_name VARCHAR, city VARCHAR, country VARCHAR);
CREATE TABLE sales    (sale_id VARCHAR PRIMARY KEY, sale_date DATE,
                       store_id VARCHAR REFERENCES stores, product_id VARCHAR REFERENCES products, quantity INT);
CREATE TABLE warranty (claim_id VARCHAR PRIMARY KEY, claim_date DATE,
                       sale_id VARCHAR REFERENCES sales, repair_status VARCHAR);
```

Then `\copy` each CSV into its table and run `sql/01_exploratory.sql` to create the indexes.
