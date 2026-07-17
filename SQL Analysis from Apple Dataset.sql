--Apple Sales Project - 1M rows sales dataset
 SELECT * FROM  category; 
 SELECT * FROM  products;
 SELECT * FROM  stores;
 SELECT * FROM  sales;
 SELECT * FROM  warranty;

 --EDA( EXPLORATORY DATA ANALYSIS TO FIND ANOMALIES,  MISSING DATA, )
 SELECT DISTINCT repair_status FROM warranty;
 SELECT COUNT(*) FROM sales;
 --index for query performance improvement
--et(execution time )-64.ms
  --pt(planning time)-0.15 ms
  --et after index-5-10 ms
  EXPLAIN ANALYZE
 SELECT * FROM sales
  WHERE product_id= 'P-44'

CREATE INDEX sales_product_id ON sales(product_id);
CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_date ON sales(sale_date);
 
 --et(execution time )-41.ms
  --pt(planning time)-0.085 ms
  --et after index-2 ms
  EXPLAIN ANALYZE
 SELECT * FROM sales
  WHERE store_id= 'ST-31'

  --Business Problems
  --1.Find the number of stores in each country?
  SELECT 
	   country,
	   COUNT(store_id) AS total_stores
  FROM stores
  GROUP BY country
  ORDER BY 2 DESC
  
--2. What is the total number of units sold by each store?
SELECT 
	s.store_id,
	st.store_name,
	SUM(s.quantity) AS total_unit_sold
FROM sales as s
join 
stores as st
on st.store_id=s.store_id
GROUP BY 1,2
ORDER BY 3 DESC
--3. Identify how many sales occurred in December 2023?
SELECT 
	COUNT(sale_id) as total_sale
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY')='12-2023'

--4. Determine how many stores have never had a warranty claim filed against any of their products?
SELECT COUNT (*) FROM stores
WHERE store_id NOT IN (
						SELECT DISTINCT store_id
						FROM sales as s 
						RIGHT JOIN warranty as w
						ON s.sale_id=w.sale_id
						)
 
---5. What percentage of warranty claims are marked as "Warranty Void"?
SELECT DISTINCT repair_status FROM warranty
no claim tha wv/total claim *100
SELECT COUNT(claim_id)/(SELECT COUNT (*)FROM warranty):: numeric)*100
   as warranty_void_percentage
FROM warranty
WHERE repair_status= 'warranty_void'

---6. Which store had the highest total units sold in the last year?
SELECT 
	st.store_name,
	s.store_id,
	SUM(quantity)
FROM sales AS s
join stores AS ST
ON s.store_id= st.store_id
WHERE sale_date>=(SELECT MAX (sale_date) FROM sales) - INTERVAL '1 YEAR'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1
--SELECT CURRENT_DATE - INTERVAL '1 YEAR'
--SELECT MIN(sale_date),MAX (sale_date) FROM sales

---7. Count the number of unique products sold in the last year.
SELECT 
	COUNT (DISTINCT(product_id))
FROM sales
WHERE sale_date>=(SELECT MAX (sale_date) FROM sales) - INTERVAL '1 YEAR'

---8. What is the average price of products in each category?
SELECT 
	c.category_name,
	c.category_id,
	AVG(p.price) as avg_price
FROM products AS p
join category as c
on p.category_id= c.category_id
GROUP BY 1,2
ORDER BY 3 DESC

--9. How many warranty claims were filed in 2020?
SELECT 
	COUNT(*) AS warranty_claim
	--EXTRACT(YEAR FROM claim_date)
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date)=2020

--10. for each store, Identify the best selling day based on highest qty sold
SELECT *
FROM
(	SELECT 
		store_id,
		TO_CHAR(sale_date, ' Day')AS day_name,
		SUM(quantity) as total_unit_sold,
		RANK () OVER (PARTITION BY store_id ORDER BY SUM (QUANTITY) DESC)AS rank
	FROM sales
	GROUP BY 1,2
) as t1
WHERE rank=1

--Medium to Hard (5 Questions)
---11. Identify least selling product of each country for each year based on total unit sold
WITH product_rank
AS
(
SELECT
	st.country,
	p.product_name,
	SUM(s.quantity) as total_qty_sold,
	RANK()OVER(PARTITION BY st.country ORDER BY SUM(quantity)) as rank
FROM sales as s
join stores as st
on s.store_id=st.store_id
join 
products as p
on s.product_id=p.product_id
GROUP BY 1,2
)
SELECT*
FROM product_rank
WHERE rank=1

--12. How many warranty claims were filed within 180 days of a product sale?
 SELECT 
 	COUNT(*)
 	--s.sale_date,
	--w.claim_date-sale_date
 FROM warranty as  w
 LEFT JOIN 
 sales as s 
 on s.sale_id=w.sale_id
 WHERE w.claim_date-sale_date<=180
--13. How many warranty claims have been filed for products launched in the last two years?

SELECT
	p.product_name,
	COUNT(w.claim_id)as no_claim,
	COUNT(s.sale_id)
FROM warranty as w
RIGHT join 
sales as s
on s.sale_id= w.sale_id
join 
products as p
on p.product_id=s.product_id
WHERE p.launch_date >= (SELECT MAX(launch_date) FROM products) - INTERVAL '2 years'
GROUP BY 1
HAVING COUNT(w.claim_id)>0

--14. List the months in the last 3 years where sales exceeded 5000 units in the usa.
SELECT
	TO_CHAR(sale_date, 'MM-YYYY')as month,
	SUM(s.quantity) as total_unit_sold
FROM sales as s
join stores as st
on s.store_id=st.store_id
WHERE st.country='USA'
	AND
	s.sale_date>=(SELECT MAX(launch_date) FROM products) - INTERVAL '3 years'
GROUP BY 1
HAVING SUM(s.quantity)>5000

--15. Which product category had the most warranty claims filed in the last 2 years?
SELECT
	c.category_name,
	COUNT(w.claim_id) as total_claims
FROM warranty as w
left join
sales as s
on w.sale_id=s.sale_id
join products as p
on p.product_id=s.product_id
join category as c
on c.category_id=p.category_id
WHERE 
	w.claim_date>=(SELECT MAX(launch_date) FROM products) - INTERVAL '2 years'
GROUP BY 1

--Complex (5 Questions)
--16. Determine the percentage chance of receiving claims after each purchase for each country.
SELECT 
	country,
	total_unit_sold,
	total_claim,
	(COALESCE(total_claim/total_unit_sold::numeric*100,0)) AS risk
FROM
(SELECT 
	st.country,
	SUM(s.quantity) as total_unit_sold,
	COUNT(w.claim_id)AS total_claim
FROM sales as s
join stores as st
on s.store_id= st.store_id
left join
warranty as w
on w.sale_id=s.sale_id
GROUP BY 1) AS t1
order by 3 desc

---17. Analyze each stores year by year growth ratio
WITH yearly_sale AS (
    SELECT
        st.store_name,
        EXTRACT(YEAR FROM sale_date) AS year,
        SUM(s.quantity * p.price) AS total_sale
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    JOIN stores   AS st ON st.store_id = s.store_id
    GROUP BY 1, 2
)
SELECT
    store_name,
    year,
    total_sale,
    LAG(total_sale) OVER (PARTITION BY store_name ORDER BY year) AS prev_year_sale,
    ROUND(
        ( (total_sale - LAG(total_sale) OVER (PARTITION BY store_name ORDER BY year))
          / NULLIF(LAG(total_sale) OVER (PARTITION BY store_name ORDER BY year), 0) * 100
        )::numeric
    , 2) AS growth_pct
FROM yearly_sale
ORDER BY store_name, year;
--18. What is the correlation between product price and warranty claims for products sold in the last five years? (Segment based on diff price)
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
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '5 YEARS'
GROUP BY 1
ORDER BY total_claims DESC;

--19. Identify the store with the highest percentage of "Paid Repaired" claims in relation to total claims filed.
  
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

  --20. Zero-claim high-revenue products
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

--21. Monthly claim rate spike detection
WITH monthly_claims AS (
    SELECT
        DATE_TRUNC('month', w.claim_date) AS claim_month,
        COUNT(w.claim_id) AS total_claims
    FROM warranty AS w
    JOIN sales AS s ON w.sale_id = s.sale_id
    WHERE w.claim_date >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY claim_month
),
monthly_sales AS (
    SELECT
        DATE_TRUNC('month', s.sale_date) AS sale_month,
        SUM(s.quantity * p.price) AS total_sales
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY sale_month
)
SELECT
    mc.claim_month,
    mc.total_claims,
    ms.total_sales,
    ROUND(mc.total_claims::numeric / NULLIF(ms.total_sales, 0) * 100, 2) AS claim_rate
FROM monthly_claims AS mc
JOIN monthly_sales AS ms ON mc.claim_month = ms.sale_month
ORDER BY mc.claim_month;

-- Q22: Avg days to claim by category
SELECT
    c.category_name,
    ROUND(AVG(
        w.claim_date - s.sale_date
    ), 1)                       AS avg_days_to_claim,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY
        w.claim_date - s.sale_date
    )                           AS median_days,
    COUNT(w.claim_id)           AS total_claims
FROM warranty  AS w
JOIN sales     AS s  ON s.sale_id    = w.sale_id
JOIN products  AS p  ON p.product_id = s.product_id
JOIN category  AS c  ON c.category_id = p.category_id
GROUP BY 1
ORDER BY avg_days_to_claim ASC;

-- Q24: Seasonality index per category
WITH monthly_cat AS (
    SELECT
        c.category_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        AVG(s.quantity * p.price)       AS avg_monthly_rev
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
    ROUND(mc.avg_monthly_rev
        / oa.base_avg, 2)   AS seasonality_index
FROM monthly_cat  mc
JOIN overall_avg  oa ON oa.ca
category_name = mc.category_name
ORDER BY mc.category_name, mc.month;

-- Q25: 3-month rolling revenue per store
WITH monthly_store AS (
    SELECT
        st.store_name,
        st.country,
        DATE_TRUNC('month', s.sale_date)
                                    AS month,
        SUM(s.quantity * p.price)  AS monthly_rev
    FROM sales    AS s
    JOIN products AS p
        ON p.product_id  = s.product_id
    JOIN stores   AS st
        ON st.store_id = s.store_id
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
            ROWS BETWEEN
                2 PRECEDING AND CURRENT ROW
        )                    AS rolling_3m_rev,
        AVG(monthly_rev) OVER ()
                             AS chain_avg_monthly
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
        WHEN rolling_3m_rev
           > chain_avg_monthly * 3
        THEN 'Above Average'
        ELSE 'Below Average'
    END                        AS performance_flag
FROM rolling
ORDER BY store_name, month;