/* 
   QUESTION 1: MARKET PULSE (YTD)
   "What is the total wholesale volume trend by year?"

   Logic Map:
   * Filter Data Scope: Limit the dataset to months January–May (month_number 1-5) across all years.
   * Aggregate: Group by year to calculate total wholesale volume.
   * Compare: Provides a "like-for-like" comparison of market performance for the same period each year.

   Note: Data for 2026 is limited to YTD (May); analysis is restricted to Jan–May for all years to ensure a fair comparison.
*/

-- Without VIEW
SELECT 
    d.year,
    sum(s.sales_units) AS total_volume
FROM fact_sales s 
    JOIN dim_dates d ON d.id = s.date_id
WHERE d.month_number <= 5
GROUP BY d.year
ORDER BY d.year DESC;

-- With VIEW
SELECT * FROM vw_market_pulse
ORDER BY year DESC;

