-- ============================================================
-- 05 · Expert Questions (Q21–Q25)
-- ROWS BETWEEN, PERCENTILE_CONT, Pareto/cumulative shares,
-- seasonality index, rolling windows
-- ============================================================

-- 21. Warranty claim rate by purchase-month cohort
-- Each sale is assigned to its original purchase month.
-- Claims are connected to the original sale through sale_id.
-- Recent cohorts may show lower rates because they have had
-- less time to produce warranty claims.

WITH monthly_purchase_cohorts AS (
    SELECT
        DATE_TRUNC('month', s.sale_date)::date AS purchase_month,
        SUM(s.quantity) AS units_sold,
        COUNT(DISTINCT w.claim_id) AS warranty_claims
    FROM sales AS s
    LEFT JOIN warranty AS w
        ON s.sale_id = w.sale_id
    GROUP BY DATE_TRUNC('month', s.sale_date)
)

SELECT
    purchase_month,
    units_sold,
    warranty_claims,
    ROUND(
        100.0 * warranty_claims / NULLIF(units_sold, 0),
        2
    ) AS lifetime_claim_rate_pct
FROM monthly_purchase_cohorts
ORDER BY purchase_month;

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

-- 24. Revenue seasonality index by product category
-- Step 1: calculate total revenue for every category and year-month
-- Step 2: calculate the average for each calendar month
-- Step 3: compare that month with the category's normal month

WITH monthly_category_revenue AS (
    SELECT
        c.category_name,
        DATE_TRUNC('month', s.sale_date)::date AS revenue_month,
        EXTRACT(MONTH FROM s.sale_date)::int AS month_number,
        SUM(s.quantity * p.price) AS monthly_revenue
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN category AS c
        ON p.category_id = c.category_id
    GROUP BY
        c.category_name,
        DATE_TRUNC('month', s.sale_date),
        EXTRACT(MONTH FROM s.sale_date)
),

calendar_month_average AS (
    SELECT
        category_name,
        month_number,
        AVG(monthly_revenue) AS average_month_revenue
    FROM monthly_category_revenue
    GROUP BY
        category_name,
        month_number
),

category_baseline AS (
    SELECT
        category_name,
        AVG(monthly_revenue) AS normal_monthly_revenue
    FROM monthly_category_revenue
    GROUP BY category_name
)

SELECT
    cma.category_name,
    cma.month_number,
    ROUND(cma.average_month_revenue, 2) AS average_month_revenue,
    ROUND(cb.normal_monthly_revenue, 2) AS normal_monthly_revenue,
    ROUND(
        cma.average_month_revenue /
        NULLIF(cb.normal_monthly_revenue, 0),
        2
    ) AS seasonality_index
FROM calendar_month_average AS cma
JOIN category_baseline AS cb
    ON cma.category_name = cb.category_name
ORDER BY
    cma.category_name,
    cma.month_number;

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
