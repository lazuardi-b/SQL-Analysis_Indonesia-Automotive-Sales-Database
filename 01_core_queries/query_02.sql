/* 
   QUESTION 2: MARKET SHARE (YTD)
   "Which 5 brands command the highest total market share by unit sales from 2023 to 2026?"

   Logic Map:
   * Data Preparation: Calculate the total wholesale volume for each brand grouped by year (Jan–May).
   * Metric Calculation: Determine the annual market share percentage for each brand relative to the total annual volume.
   * Ranking: Apply a ranking function to isolate the top 5 brands by performance per year.

   Note: Data for 2026 is limited to YTD (May); analysis is restricted to Jan–May for all years to ensure a fair comparison.
*/

-- Without VIEW
WITH annual_brand_sales AS (
    SELECT 
        d.year,
        b.brand_name,
        sum(s.sales_units) AS total_sold_units
    FROM fact_sales s 
        JOIN dim_cars c ON c.id = s.car_id
        JOIN dim_brands b ON b.id = c.brand_id
        JOIN dim_dates d ON d.id = s.date_id
    WHERE d.month_number <= 5
    GROUP BY d.year, b.brand_name
),
market_share AS (
    SELECT
        year,
        brand_name,
        round(total_sold_units * 100.0 / sum(total_sold_units)
            OVER (PARTITION BY year), 2) AS pct_market_share,
        rank() OVER (PARTITION BY year ORDER BY total_sold_units DESC) AS sales_rank
    FROM annual_brand_sales
)
SELECT *
FROM market_share
WHERE sales_rank <= 5
ORDER BY year DESC, sales_rank ASC;

-- With VIEW
SELECT * FROM vw_market_share
ORDER BY year DESC, sales_rank ASC;