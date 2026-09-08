-- ============================================================
-- 01 · Exploratory Data Analysis + Performance Setup
-- Apple Retail Sales — 1M+ rows · 73 stores · 35 countries
-- Run this file first: it validates the data and creates the
-- indexes every later query depends on.
-- ============================================================

-- Quick shape check on all five tables
SELECT * FROM category LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM stores   LIMIT 10;
SELECT * FROM sales    LIMIT 10;
SELECT * FROM warranty LIMIT 10;

-- Row counts and key-field sanity
SELECT COUNT(*) AS total_sales_rows FROM sales;          -- 1,040,191
SELECT DISTINCT repair_status FROM warranty;             -- claim status taxonomy
SELECT MIN(sale_date), MAX(sale_date) FROM sales;        -- Jan 2019 – Aug 2024

-- ------------------------------------------------------------
-- Index strategy: the three columns every business query
-- filters or joins on. Timings measured with EXPLAIN ANALYZE.
--
--   Filter by product_id : 64 ms -> 5 ms   (92% faster)
--   Filter by store_id   : 41 ms -> 2 ms   (95% faster)
-- ------------------------------------------------------------
CREATE INDEX sales_product_id ON sales(product_id);
CREATE INDEX sales_store_id   ON sales(store_id);
CREATE INDEX sales_sale_date  ON sales(sale_date);

-- Verify (before/after comparison)
EXPLAIN ANALYZE
SELECT * FROM sales WHERE product_id = 'P-44';

EXPLAIN ANALYZE
SELECT * FROM sales WHERE store_id = 'ST-31';
