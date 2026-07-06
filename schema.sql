-- CREATE TABLE 

-- Independent Table
CREATE TABLE dim_brands (
    id bigint GENERATED ALWAYS AS IDENTITY,
    brand_name varchar (50) NOT NULL UNIQUE,
    brand_hq varchar (100) NOT NULL,
    quality_index numeric (3, 2) CHECK (quality_index >= 0 AND quality_index <= 1), -- percentage convert to decimal, ex. 98% means 0.98

   CONSTRAINT pk_dim_brands PRIMARY KEY (id)
);

CREATE TABLE dim_productions (
    id bigint GENERATED ALWAYS AS IDENTITY,
    production_type varchar (20),
    source_country varchar (50),

    CONSTRAINT pk_dim_production PRIMARY KEY (id)
);

CREATE TABLE dim_dates (
    id bigint GENERATED ALWAYS AS IDENTITY,
    month varchar (10) NOT NULL,
    month_number int NOT NULL,
    year int NOT NULL,

    CONSTRAINT pk_dim_dates PRIMARY KEY (id)
);

-- Dependent Table
CREATE TABLE dim_cars (
    id bigint GENERATED ALWAYS AS IDENTITY,
    brand_id bigint NOT NULL,
    model_name varchar (100) NOT NULL,
    transmission_type varchar (20),
    fuel_type varchar (20),
    fuel_category varchar (20),

    CONSTRAINT pk_dim_cars PRIMARY KEY (id),
    CONSTRAINT fk_dim_cars FOREIGN KEY (brand_id) 
        REFERENCES dim_brands (id) ON DELETE CASCADE
);

CREATE TABLE fact_sales (
    id bigint GENERATED ALWAYS AS IDENTITY,
    car_id bigint NOT NULL,
    production_id bigint NOT NULL,
    date_id bigint NOT NULL,
    sales_units int NOT NULL CHECK (sales_units >= 0),

    CONSTRAINT pk_fact_sales PRIMARY KEY (id),
    CONSTRAINT fk_sales_car FOREIGN KEY (car_id)
        REFERENCES dim_cars (id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_production FOREIGN KEY (production_id)
        REFERENCES dim_productions (id) ON DELETE CASCADE,
    CONSTRAINT fk_sales_dates FOREIGN KEY (date_id)
        REFERENCES dim_dates (id) ON DELETE CASCADE
);

-- Temporary Tables
CREATE TABLE temp_brands (
    brand_name_clean text,
    brand_origin text,
    quality_index text
);

CREATE TABLE temp_productions (
    cbu_ckd_clean text,
    origin_country_clean text
);

CREATE TABLE temp_dates (
    month text,
    month_number text,
    year text
);

CREATE TABLE temp_cars (
    brand_name_clean text,
    model_name text,
    transmission_clean text,
    fuel_type_clean text,
    fuel_category text
);

CREATE TABLE temp_sales (
    brand_name_clean text,
    model_name text,
    transmission_clean text,
    fuel_type_clean text,
    fuel_category text,
    cbu_ckd_clean text,
    origin_country_clean text,
    month text,
    month_number text,
    year text,
    sales_units text
);

-- Import raw .csv file into temp_tables
COPY temp_brands
FROM 'D:\04 Data Analyst\0 Data Car Project\car_sales_tables_fix\dim_brands.csv'
WITH (FORMAT CSV, HEADER, NULL 'NULL');

COPY temp_productions
FROM 'D:\04 Data Analyst\0 Data Car Project\car_sales_tables_fix\dim_productions.csv'
WITH (FORMAT CSV, HEADER, NULL 'NULL');

COPY temp_dates
FROM 'D:\04 Data Analyst\0 Data Car Project\car_sales_tables_fix\dim_dates.csv'
WITH (FORMAT CSV, HEADER, NULL 'NULL');

COPY temp_cars
FROM 'D:\04 Data Analyst\0 Data Car Project\car_sales_tables_fix\dim_cars.csv'
WITH (FORMAT CSV, HEADER, NULL 'NULL');

COPY temp_sales
FROM 'D:\04 Data Analyst\0 Data Car Project\car_sales_tables_fix\fact_sales.csv'
WITH (FORMAT CSV, HEADER, NULL 'NULL');

-- Populate / Import to actual table
INSERT INTO dim_brands (brand_name, brand_hq, quality_index)
SELECT 
    brand_name_clean,
    brand_origin,
    quality_index::numeric
FROM temp_brands;

INSERT INTO dim_productions (production_type, source_country)
SELECT 
    cbu_ckd_clean,
    origin_country_clean
FROM temp_productions;

INSERT INTO dim_dates (month, month_number, year)
SELECT
    month,
    month_number::int,
    year::int
FROM temp_dates;

INSERT INTO dim_cars (brand_id, model_name, transmission_type, fuel_type, fuel_category)
SELECT DISTINCT
    b.id,
    tc.model_name,
    tc.transmission_clean,
    tc.fuel_type_clean,
    tc.fuel_category
FROM temp_cars AS tc 
    JOIN dim_brands AS b
        ON b.brand_name = tc.brand_name_clean
;

INSERT INTO fact_sales (car_id, production_id, date_id, sales_units)
SELECT 
    c.id,
    p.id,
    d.id,
    ts.sales_units::int
FROM temp_sales AS ts 
    JOIN dim_brands AS b
        ON b.brand_name = ts.brand_name_clean
    JOIN dim_cars AS c 
        ON c.brand_id = b.id
        AND c.model_name = ts.model_name
        AND c.transmission_type = ts.transmission_clean
        AND c.fuel_type = ts.fuel_type_clean
        AND c.fuel_category = ts.fuel_category
    JOIN dim_productions AS p 
        ON p.production_type = ts.cbu_ckd_clean
        AND p.source_country = ts.origin_country_clean
    JOIN dim_dates AS d
        ON d.month = ts.month
        AND d.month_number = ts.month_number::int
        AND d.year = ts.year::int
;

-- Handling NULL values (dim_productions & dim_cars)
-- We need to change the NULL to Unknown or N/A
-- Unkown: it supposed to be there but none
-- N/A: it just not applicable so it can't be fill

UPDATE dim_productions
SET production_type = 'Unknown'
WHERE production_type IS NULL
    OR production_type = '';

UPDATE dim_productions
SET source_country = 'Unknown'
WHERE source_country IS NULL
    OR source_country = '';

UPDATE dim_cars
SET transmission_type = 'Unknown'
WHERE transmission_type IS NULL
    OR transmission_type = '';

UPDATE dim_cars
SET fuel_type = 'Unknown'
WHERE fuel_type IS NULL
    OR fuel_type = '';

UPDATE dim_cars
SET fuel_category = 'Unknown'
WHERE fuel_category IS NULL
    OR fuel_category = '';

-- INDEX (consider JOIN and WHERE clause)
-- 1. Indexes for fact_sales to optimize JOINS
-- 2. Index for dim_cars to optimize Brand -> Model lookup
-- 3. Composite index for dim_dates for efficient time filtering
CREATE INDEX idx_sales_carid ON fact_sales (car_id);
CREATE INDEX idx_sales_productionid ON fact_sales (production_id);
CREATE INDEX idx_sales_dateid ON fact_sales (date_id);
CREATE INDEX idx_cars_brandid ON dim_cars (brand_id);
CREATE INDEX idx_dates_yearmonth ON dim_dates (year, month_number);

-- VIEW (do JOIN and SELECT the necessary columns)
-- QUESTION 01 VIEW
CREATE VIEW vw_market_pulse AS
SELECT 
    d.year,
    sum(s.sales_units) AS total_volume
FROM fact_sales s 
    JOIN dim_dates d ON d.id = s.date_id
WHERE d.month_number <= 5
GROUP BY d.year;

-- QUESTION 02 VIEW
CREATE VIEW vw_market_share AS
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
WHERE sales_rank <= 5;

-- QUESTION 03 VIEW
CREATE VIEW vw_productions AS
SELECT
    d.year,
    p.production_type,
    sum(s.sales_units) AS total_sales
FROM fact_sales s 
    JOIN dim_dates d ON d.id = s.date_id
    JOIN dim_productions p ON p.id = s.production_id
WHERE d.month_number <= 5 
     AND p.production_type != 'Unknown'
GROUP BY d.year, p.production_type;

-- QUESTION 04 VIEW
CREATE VIEW vw_top_models AS
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
SELECT *
FROM model_market_share
WHERE model_rank <= 3;

-- QUESTION 05 VIEW
CREATE VIEW vw_seasonality AS
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
WHERE monthly_rank <= 3;