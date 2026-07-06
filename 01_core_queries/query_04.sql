/* 
   QUESTION 4: TOP MODELS (YTD)
   "Which specific car models are the top 3 volume drivers for each of the top 5 brands?"

   Logic Map:
   * Brand Identification: Isolate the top 5 brands by annual sales volume using a ranking window function.
   * Granular Analysis: Calculate sales volume and percentage contribution for every model within those top brands.
   * Drill-down: Rank models within each brand and filter to extract the top 3 drivers per brand, per year.

   Note: Data for 2026 is limited to YTD (May); analysis is restricted to Jan–May for all years to ensure a fair comparison.
*/

-- Without VIEW
WITH annual_brand_sales AS (
    SELECT 
        d.year,
        b.brand_name,
        sum(s.sales_units) AS total_brand_sales,
        rank() OVER (PARTITION BY d.year ORDER BY sum(s.sales_units) DESC) AS brand_rank
    FROM fact_sales s 
        JOIN dim_cars c ON c.id = s.car_id
        JOIN dim_brands b ON b.id = c.brand_id
        JOIN dim_dates d ON d.id = s.date_id
    WHERE d.month_number <= 5
    GROUP BY d.year, b.brand_name
),
annual_model_sales AS (
    SELECT 
        d.year,
        b.brand_name,
        c.model_name,
        sum(s.sales_units) AS total_model_sales
    FROM fact_sales s 
        JOIN dim_cars c ON c.id = s.car_id
        JOIN dim_brands b ON b.id = c.brand_id
        JOIN dim_dates d ON d.id = s.date_id
    WHERE d.month_number <= 5 
    GROUP BY d.year,b.brand_name, c.model_name
),
model_market_share AS (
    SELECT 
        ams.year,
        ams.brand_name,
        ams.model_name,
        abs.brand_rank,
        ams.total_model_sales,
        round(ams.total_model_sales * 100.0 / NULLIF(sum (ams.total_model_sales)
            OVER (PARTITION BY ams.year, ams.brand_name), 0), 2) AS pct_market_share,
        rank() OVER (PARTITION BY ams.year, ams.brand_name ORDER BY ams.total_model_sales DESC) AS model_rank
    FROM annual_model_sales ams
        JOIN annual_brand_sales abs ON abs.year = ams.year
            AND abs.brand_name = ams.brand_name
    WHERE abs.brand_rank <= 5
)
SELECT 
    year,
    brand_name,
    model_name,
    pct_market_share,
    model_rank
FROM model_market_share
WHERE model_rank <= 3
ORDER BY year DESC, brand_rank ASC, model_rank ASC;

-- With VIEW
SELECT * FROM vw_top_models 
ORDER BY year DESC, brand_rank ASC, model_rank ASC; 
