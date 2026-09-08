-- ============================================================
-- 02 · Foundational Questions (Q1–Q10)
-- JOINs, GROUP BY, date filters, aggregations
-- ============================================================

-- 1. Number of stores in each country
SELECT
    country,
    COUNT(store_id) AS total_stores
FROM stores
GROUP BY country
ORDER BY total_stores DESC;

-- 2. Total units sold by each store
SELECT
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- 3. Sales count in December 2023
SELECT COUNT(sale_id) AS total_sales
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '12-2023';

-- 4. Stores that have never had a warranty claim filed
SELECT COUNT(*) AS stores_without_claims
FROM stores
WHERE store_id NOT IN (
    SELECT DISTINCT s.store_id
    FROM sales AS s
    RIGHT JOIN warranty AS w ON s.sale_id = w.sale_id
);

-- 5. Percentage of warranty claims marked "Warranty Void"
SELECT
    ROUND(
        COUNT(claim_id) FILTER (WHERE repair_status = 'Warranty Void')::numeric
        / COUNT(*) * 100
    , 2) AS warranty_void_pct
FROM warranty;

-- 6. Store with highest units sold in the last year of data
-- (anchored on MAX(sale_date), not CURRENT_DATE — the dataset ends Aug 2024)
SELECT
    st.store_name,
    s.store_id,
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st ON s.store_id = st.store_id
WHERE s.sale_date >= (SELECT MAX(sale_date) FROM sales) - INTERVAL '1 year'
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1;

-- 7. Unique products sold in the last year of data
SELECT COUNT(DISTINCT product_id) AS unique_products
FROM sales
WHERE sale_date >= (SELECT MAX(sale_date) FROM sales) - INTERVAL '1 year';

-- 8. Average product price per category
SELECT
    c.category_name,
    c.category_id,
    AVG(p.price) AS avg_price
FROM products AS p
JOIN category AS c ON p.category_id = c.category_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- 9. Warranty claims filed in 2020
SELECT COUNT(*) AS warranty_claims
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2020;

-- 10. Best-selling day per store (by quantity)
SELECT *
FROM (
    SELECT
        store_id,
        TO_CHAR(sale_date, 'Day') AS day_name,
        SUM(quantity) AS total_units_sold,
        RANK() OVER (PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rnk
    FROM sales
    GROUP BY 1, 2
) AS t
WHERE rnk = 1;
