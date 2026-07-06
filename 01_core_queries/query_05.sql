/* 
   QUESTION 5: SEASONALITY ANALYSIS
   "Which months consistently show the highest sales volume, and do these 'peak' months remain the same across 2023, 2024, and 2025?"

   Logic Map:
   * Data Aggregation: Calculate total wholesale volume grouped by year and month.
   * Performance Ranking: Apply a ranking window function to identify the top 3 performing months for each individual year.
   * Pattern Identification: Compare the top-ranked months across years (2023–2025) to determine if there is a consistent seasonal peak.

   Note: Analysis is restricted to years (2023–2025) to provide a complete year-over-year seasonal comparison, excluding the incomplete 2026 data.
*/

-- Without VIEW
WITH monthly_sales AS (
    SELECT
        d.year,
        d.month,
        sum(s.sales_units) AS total_units,
        rank() OVER (PARTITION BY d.year ORDER BY sum(s.sales_units) DESC) AS monthly_rank
    FROM fact_sales s  
        JOIN dim_dates d ON d.id = s.date_id
    WHERE d.year BETWEEN 2023 AND 2025
    GROUP BY d.year, d.month
)
SELECT * 
FROM monthly_sales 
WHERE monthly_rank <= 3
ORDER BY year DESC, monthly_rank ASC;

-- With VIEW
SELECT * FROM vw_seasonality
ORDER BY year DESC, monthly_rank ASC;