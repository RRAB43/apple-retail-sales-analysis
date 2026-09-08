-- ============================================================
-- 04 · Advanced Questions (Q16–Q20)
-- Window functions, LAG(), COALESCE, NULLIF, FILTER
-- ============================================================

-- 16. Probability of a warranty claim after purchase, by country
SELECT
    country,
    total_units_sold,
    total_claims,
    COALESCE(ROUND(total_claims / total_units_sold::numeric * 100, 2), 0) AS claim_risk_pct
FROM (
    SELECT
        st.country,
        SUM(s.quantity)   AS total_units_sold,
        COUNT(w.claim_id) AS total_claims
    FROM sales AS s
    JOIN stores AS st ON s.store_id = st.store_id
    LEFT JOIN warranty AS w ON w.sale_id = s.sale_id
    GROUP BY 1
) AS t
ORDER BY claim_risk_pct DESC;

-- 17. Year-over-year growth per store
WITH yearly_sale AS (
    SELECT
        st.store_name,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        SUM(s.quantity * p.price) AS total_sale
    FROM sales AS s
    JOIN products AS p  ON s.product_id = p.product_id
    JOIN stores   AS st ON st.store_id  = s.store_id
    GROUP BY 1, 2
)
SELECT
    store_name,
    year,
    total_sale,
    LAG(total_sale) OVER (PARTITION BY store_name ORDER BY year) AS prev_year_sale,
    ROUND(
        ((total_sale - LAG(total_sale) OVER (PARTITION BY store_name ORDER BY year))
          / NULLIF(LAG(total_sale) OVER (PARTITION BY store_name ORDER BY year), 0) * 100
        )::numeric
    , 2) AS growth_pct
FROM yearly_sale
ORDER BY store_name, year;

-- 18. Price segment vs warranty claims (last 5 years of claim data)
SELECT
    CASE
        WHEN p.price < 500  THEN 'Budget (<500)'
        WHEN p.price < 1000 THEN 'Mid (500-999)'
        WHEN p.price < 1500 THEN 'Premium (1000-1499)'
        ELSE 'Luxury (1500+)'
    END AS price_segment,
    COUNT(w.claim_id) AS total_claims
FROM warranty AS w
JOIN sales    AS s ON w.sale_id    = s.sale_id
JOIN products AS p ON p.product_id = s.product_id
WHERE w.claim_date >= (SELECT MAX(claim_date) FROM warranty) - INTERVAL '5 years'
GROUP BY 1
ORDER BY total_claims DESC;

-- 19. Store with the highest share of "Paid Repaired" claims
SELECT
    s.store_id,
    COUNT(w.claim_id) AS total_claims,
    COUNT(w.claim_id) FILTER (WHERE w.repair_status = 'Paid Repaired') AS paid_repaired_claims,
    ROUND(
        COUNT(w.claim_id) FILTER (WHERE w.repair_status = 'Paid Repaired')::numeric
        / COUNT(w.claim_id) * 100
    , 2) AS paid_repaired_pct
FROM warranty AS w
JOIN sales AS s ON w.sale_id = s.sale_id
GROUP BY s.store_id
ORDER BY paid_repaired_pct DESC
LIMIT 1;

-- 20. Zero-claim, high-revenue products (> $100K revenue, no claims ever)
SELECT
    p.product_id,
    p.product_name,
    SUM(s.quantity * p.price) AS total_revenue
FROM sales AS s
JOIN products AS p ON s.product_id = p.product_id
LEFT JOIN warranty AS w ON s.sale_id = w.sale_id
WHERE w.claim_id IS NULL
GROUP BY p.product_id, p.product_name
HAVING SUM(s.quantity * p.price) > 100000
ORDER BY total_revenue DESC;
