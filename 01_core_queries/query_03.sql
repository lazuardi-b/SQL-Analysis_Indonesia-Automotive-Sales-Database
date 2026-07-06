/* 
   QUESTION 3: PRODUCTION STRATEGY (CBU VS. CKD) (YTD)
   "What is the distribution of total sales volume across production types (CBU vs. CKD) for the years 2023 to 2026?"

   Logic Map:
   * Categorization: Partition sales volume by production type (CBU or CKD) to identify operational strategy.
   * Trend Analysis: Aggregate volumes by year to observe shifts in production reliance over time.
   * Data Filtering: Exclude 'Unknown' production types to ensure accuracy in the distribution analysis.

   Note: Data for 2026 is limited to YTD (May); analysis is restricted to Jan–May for all years to ensure a fair comparison.
*/

-- Without VIEW
SELECT
    d.year,
    p.production_type,
    sum(s.sales_units) AS total_sales
FROM fact_sales s 
    JOIN dim_dates d ON d.id = s.date_id
    JOIN dim_productions p ON p.id = s.production_id
WHERE d.month_number <= 5 
     AND p.production_type != 'Unknown'
GROUP BY d.year, p.production_type
ORDER BY d.year DESC, total_sales DESC;

-- With VIEW
SELECT * FROM vw_productions
ORDER BY year DESC, total_sales DESC;