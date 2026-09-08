-- ============================================================
-- 05 · Expert Questions (Q21–Q25)
-- ROWS BETWEEN, PERCENTILE_CONT, Pareto/cumulative shares,
-- seasonality index, rolling windows
-- ============================================================

-- 21. Monthly claim-rate trend (last year of data) — spike detection
WITH monthly_claims AS (
    SELECT
        DATE_TRUNC('month', w.claim_date) AS claim_month,
        COUNT(w.claim_id) AS total_claims
    FROM warranty AS w
    JOIN sales AS s ON w.sale_id = s.sale_id
    WHERE w.claim_date >= (SELECT MAX(claim_date) FROM warranty) - INTERVAL '1 year'
    GROUP BY 1
),
monthly_sales AS (
    SELECT
        DATE_TRUNC('month', s.sale_date) AS sale_month,
        SUM(s.quantity * p.price) AS total_sales
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    WHERE s.sale_date >= (SELECT MAX(sale_date) FROM sales) - INTERVAL '1 year'
    GROUP BY 1
)
SELECT
    mc.claim_month,
    mc.total_claims,
    ms.total_sales,
    ROUND(mc.total_claims::numeric / NULLIF(ms.total_sales, 0) * 100, 2) AS claim_rate
FROM monthly_claims AS mc
JOIN monthly_sales AS ms ON mc.claim_month = ms.sale_month
ORDER BY mc.claim_month;

-- 22. Average and median days from sale to warranty claim, by category
SELECT
    c.category_name,
    ROUND(AVG(w.claim_date - s.sale_date), 1) AS avg_days_to_claim,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY w.claim_date - s.sale_date) AS median_days,
    COUNT(w.claim_id) AS total_claims
FROM warranty AS w
JOIN sales    AS s ON s.sale_id     = w.sale_id
JOIN products AS p ON p.product_id  = s.product_id
JOIN category AS c ON c.category_id = p.category_id
GROUP BY 1
ORDER BY avg_days_to_claim ASC;

-- 23. Revenue concentration (Pareto): cumulative revenue share by product
-- Backs the finding that the top 3 products drive ~34% of total revenue —
-- a concentration risk if any one product faces supply disruption.
WITH product_rev AS (
    SELECT
        p.product_name,
        SUM(s.quantity * p.price) AS revenue
    FROM sales AS s
    JOIN products AS p ON p.product_id = s.product_id
    GROUP BY 1
)
SELECT
    product_name,
    revenue,
    ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS revenue_share_pct,
    ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
              / SUM(revenue) OVER (), 2) AS cumulative_share_pct
FROM product_rev
ORDER BY revenue DESC;

-- 24. Seasonality index per category (monthly avg vs category baseline)
WITH monthly_cat AS (
    SELECT
        c.category_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        AVG(s.quantity * p.price) AS avg_monthly_rev
    FROM sales    AS s
    JOIN products AS p ON p.product_id  = s.product_id
    JOIN category AS c ON c.category_id = p.category_id
    GROUP BY 1, 2
),
overall_avg AS (
    SELECT
        category_name,
        AVG(avg_monthly_rev) AS base_avg
    FROM monthly_cat
    GROUP BY 1
)
SELECT
    mc.category_name,
    mc.month,
    ROUND((mc.avg_monthly_rev / oa.base_avg)::numeric, 2) AS seasonality_index
FROM monthly_cat AS mc
JOIN overall_avg AS oa ON oa.category_name = mc.category_name
ORDER BY mc.category_name, mc.month;

-- 25. 3-month rolling revenue per store, flagged vs chain average
WITH monthly_store AS (
    SELECT
        st.store_name,
        st.country,
        DATE_TRUNC('month', s.sale_date) AS month,
        SUM(s.quantity * p.price) AS monthly_rev
    FROM sales    AS s
    JOIN products AS p  ON p.product_id = s.product_id
    JOIN stores   AS st ON st.store_id  = s.store_id
    GROUP BY 1, 2, 3
),
rolling AS (
    SELECT
        store_name,
        country,
        month,
        monthly_rev,
        SUM(monthly_rev) OVER (
            PARTITION BY store_name
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3m_rev,
        AVG(monthly_rev) OVER () AS chain_avg_monthly
    FROM monthly_store
)
SELECT
    store_name,
    country,
    month,
    monthly_rev,
    rolling_3m_rev,
    ROUND(chain_avg_monthly, 0) AS chain_avg,
    CASE
        WHEN rolling_3m_rev > chain_avg_monthly * 3 THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_flag
FROM rolling
ORDER BY store_name, month;
