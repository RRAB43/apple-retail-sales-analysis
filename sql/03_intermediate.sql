-- ============================================================
-- 03 · Intermediate Questions (Q11–Q15)
-- CTEs, RANK(), subqueries, HAVING
-- ============================================================

-- 11. Least-selling product per country (by units sold)
WITH product_rank AS (
    SELECT
        st.country,
        p.product_name,
        SUM(s.quantity) AS total_qty_sold,
        RANK() OVER (PARTITION BY st.country ORDER BY SUM(s.quantity)) AS rnk
    FROM sales AS s
    JOIN stores   AS st ON s.store_id  = st.store_id
    JOIN products AS p  ON s.product_id = p.product_id
    GROUP BY 1, 2
)
SELECT *
FROM product_rank
WHERE rnk = 1;

-- 12. Warranty claims filed within 180 days of the product sale
SELECT COUNT(*) AS claims_within_180d
FROM warranty AS w
LEFT JOIN sales AS s ON s.sale_id = w.sale_id
WHERE w.claim_date - s.sale_date <= 180;

-- 13. Claims for products launched in the last two years (per product)
SELECT
    p.product_name,
    COUNT(w.claim_id) AS total_claims,
    COUNT(s.sale_id)  AS total_sales
FROM warranty AS w
RIGHT JOIN sales   AS s ON s.sale_id    = w.sale_id
JOIN products      AS p ON p.product_id = s.product_id
WHERE p.launch_date >= (SELECT MAX(launch_date) FROM products) - INTERVAL '2 years'
GROUP BY 1
HAVING COUNT(w.claim_id) > 0;

-- 14. Months in the last 3 years of data where USA sales exceeded 5,000 units
SELECT
    TO_CHAR(s.sale_date, 'MM-YYYY') AS month,
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st ON s.store_id = st.store_id
WHERE st.country = 'USA'
  AND s.sale_date >= (SELECT MAX(sale_date) FROM sales) - INTERVAL '3 years'
GROUP BY 1
HAVING SUM(s.quantity) > 5000;

-- 15. Product category with the most warranty claims in the last 2 years of data
SELECT
    c.category_name,
    COUNT(w.claim_id) AS total_claims
FROM warranty AS w
LEFT JOIN sales AS s ON w.sale_id = s.sale_id
JOIN products  AS p ON p.product_id  = s.product_id
JOIN category  AS c ON c.category_id = p.category_id
WHERE w.claim_date >= (SELECT MAX(claim_date) FROM warranty) - INTERVAL '2 years'
GROUP BY 1
ORDER BY total_claims DESC;
