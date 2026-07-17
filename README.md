Business Problem

Apple operates 73 retail stores across 35 countries, generating hundreds of millions in annual revenue. This project answers the questions a real retail analytics team faces every quarter:


Which stores and markets are growing — and which are silently declining?
Are warranty claims a quality signal or a data anomaly?
What does the revenue forecast look like for 2024, and what scenarios should leadership plan for?
Which products earn the most while costing the least in after-sale support?
Where should Apple focus inventory, marketing, and operations resources next?


This is not a tutorial project. It is a structured analytics engagement on a real-scale dataset, designed to mirror the work done by data analysts and scientists at top-tier retail and tech companies.


📂 Dataset Overview

TableRowsDescriptionsales1,040,191Every transaction: store, product, quantity, dateproducts64Product catalog with price and launch datestores73Store locations with country mappingcategory10Product category taxonomywarranty30,836Warranty claims with status and claim date

Date range: January 2019 – August 2024
Geography: 35 countries across North America, Europe, Asia-Pacific, Middle East, and Latin America
Revenue scale: ~$993M total across the dataset period


🗂️ Repository Structure

apple-sales-analysis/
│
├── data/                          # Raw CSV files
│   ├── sales.csv
│   ├── products.csv
│   ├── stores.csv
│   ├── category.csv
│   └── warranty.csv
│
├── sql/                           # All 25 SQL queries
│   ├── 01_exploratory.sql         # EDA + index creation
│   ├── 02_basic_questions.sql     # Q1–Q10
│   ├── 03_intermediate.sql        # Q11–Q15
│   ├── 04_advanced.sql            # Q16–Q20
│   └── 05_expert.sql              # Q21–Q25 (new)
│
├── dashboards/                    # Interactive HTML dashboards
│   ├── apple_sales_dashboard.html        # Main KPI overview
│   └── apple_advanced_layers.html        # Predictive + Product + SQL layers
│
├── notebooks/                     # Python analysis (optional)
│   └── apple_eda.ipynb
│
├── recommendations/
│   └── executive_recommendations.md     # Business recommendations
│
└── README.md


🔍 Analysis Approach

Phase 1 — Exploratory Data Analysis

Before writing a single business query, I performed EDA to validate data quality:


Confirmed 1,040,191 sales records with no nulls in key fields
Identified a data gap in Q1 2021 (only $3M revenue vs $30M+ typical) — flagged as a potential pipeline issue, not a real performance drop
Discovered the UAE cluster showing 66.4% warranty claim rate — statistically impossible under normal conditions, requiring investigation
Verified distinct repair_status values and date ranges across all five tables


Phase 2 — Performance Optimization

With 1M+ rows, query performance matters. I created three indexes and measured execution time before and after:

sqlCREATE INDEX sales_product_id ON sales(product_id);
CREATE INDEX sales_store_id   ON sales(store_id);
CREATE INDEX sales_sale_date  ON sales(sale_date);

QueryBefore IndexAfter IndexImprovementFilter by product_id64ms5ms92% fasterFilter by store_id41ms2ms95% faster

Phase 3 — 25 Business Questions

Structured across four difficulty tiers:

TierQuestionsSkillsFoundationalQ1–Q10JOINs, GROUP BY, date filters, aggregationsIntermediateQ11–Q15CTEs, RANK(), subqueries, HAVINGAdvancedQ16–Q20Window functions, LAG(), COALESCE, NULLIF, FILTERExpertQ21–Q25ROWS BETWEEN, PERCENTILE_CONT, seasonality index, rolling windows, zero-claim detection

Phase 4 — Predictive Layer

Linear trend model built on 20 quarters of actuals (2019–2023) to project 2024 full-year revenue at $251M, with an interactive scenario simulator allowing ±growth rate and claim reduction adjustments.

Phase 5 — Product Intelligence

Price-segment vs warranty claim rate analysis revealed a clear inverse relationship: Budget products (<$500) carry 4.4% avg claim rate — nearly 5× the Luxury tier's 0.9% — while contributing only 8.2% of total revenue.


📊 Key Findings

Revenue


Peak year: 2022 at $296.7M — 66% YoY growth driven by iPhone 14 launch cycle and post-COVID demand recovery
2023 declined to $159.2M — partially explained by the end of the iPhone 14 super-cycle and macro headwinds
USA accounts for 30.8% of global revenue across just 10 stores — the highest revenue-per-store market globally
Q4 seasonality is consistent: every year shows a 30–40% revenue uplift in Q4 vs Q2, driven by iPhone launch cycles


Warranty & Risk


UAE: 66.4% warranty claim rate on 17,787 units sold — the highest by a factor of 2.4× vs Spain (27.5%), the next highest country. Estimated warranty liability: $968K–$4.2M depending on claim resolution type
Budget products (<$500) generate the most warranty claims at 4.4% avg — making them the worst risk-adjusted category in the portfolio
iPhone 14 series shows the highest claim rates among top-10 revenue products (3.08–3.21%) — an early-adopter quality signal
Mac mini and Mac Studio together: $76.8M in revenue with zero warranty claims — the most capital-efficient products in the catalog


Product


MacBook Pro M1 Max captures 96.6% of its lifetime revenue in the first 12 months — confirming Apple's buzz-launch model where year-1 is make-or-break
Top 3 products drive 34% of total revenue — high concentration risk if any single product faces supply disruption
Seasonality index reveals Wearables peak in January (index 1.29×) and Audio peaks in June (1.18×) — actionable for inventory planning



💡 Business Recommendations

See recommendations/executive_recommendations.md for the full executive brief.

TL;DR:


Investigate UAE immediately — a 66.4% claim rate is not a performance issue, it's a systemic failure. Estimated exposure: $968K–$4.2M
Double down on Luxury products — $289.5M revenue, 0.9% claim rate. Best risk-adjusted segment in the portfolio
Use Q4 forecast for inventory planning — 30–40% uplift every Q4 is predictable and should drive procurement decisions 6 months in advance



🛠️ Technical Stack

ToolPurposePostgreSQLPrimary query engine for all 25 SQL questionsPython (pandas, numpy)Data validation, metric computation, trend modelingChart.jsInteractive dashboard visualizationsHTML/CSS/JavaScriptSelf-contained portable dashboard (no backend required)EXPLAIN ANALYZEQuery performance profiling and index validation


🚀 How to Run

SQL Queries


Load all five CSV files into PostgreSQL as tables matching their filenames
Run sql/01_exploratory.sql first to create indexes
Execute queries in order — each file builds on the previous


Dashboard


Download dashboards/apple_sales_dashboard.html or dashboards/apple_advanced_layers.html
Open in any modern browser — no server, no dependencies required
The advanced dashboard has three tabs: Predictive Analytics, Product Deep-Dive, and SQL Deep-Dive



👤 Author

Built as a portfolio project demonstrating end-to-end data analytics skills:
SQL query design → performance optimization → business insight generation → predictive modeling → executive communication


Dataset sourced for educational and portfolio purposes. All business insights are analytical observations based on the dataset provided.
