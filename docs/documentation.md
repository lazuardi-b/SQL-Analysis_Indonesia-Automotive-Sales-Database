# Database Documentation

This document covers the technical implementation of the Indonesian Automotive Sales Database, including it's schema design, entity relationships, and the SQL components that power the analysis.

---

## Table of Contents

- [Project Structure](#project-structure)
- [ETL Workflow](#etl-workflow)
- [Database Design](#database-design)
  - [Entity Relationship Diagram (ERD)](#entity-relationship-diagram-erd)
  - [Entity Definitions](#entity-definitions)
  - [Relationship Mapping](#relationship-mapping)
- [Database Setup](#database-setup)
- [Optimization](#optimization)
  - [Indexes](#indexes)
  - [SQL Views](#sql-views)
- [Design Decisions](#design-decisions)
- [Limitations](#limitations)

---

## Project Structure

The repository is organized into separate components for documentation, database implementation, and SQL analysis.

| File / Folder | Purpose |
|---------------|---------|
| `README.md` | Project overview, business analysis, and key findings. |
| `schema.sql` | Complete database setup, including table creation, staging tables, data import, indexes, and SQL `VIEW`s. |
| `01_core_queries/` | SQL queries used to answer the five core business questions presented in the README. |
| `02_exploratory_queries/` | Additional SQL queries exploring trends and business questions beyond the project's primary scope. |
| `docs/database_documentation.md` | Technical documentation covering the database design and implementation. |
| `assets/` | ERD diagram and visualizations used throughout the project. |

---

## ETL Workflow

The database was built through a manual ETL (Extract, Transform, Load) process that converts GAIKINDO's monthly PDF reports into a normalized relational database.

```text
GAIKINDO PDF Reports
        ↓
CSV Conversion
        ↓
Power Query Transformation
        ↓
Normalized CSV Tables
        ↓
Temporary Staging Tables (PostgreSQL)
        ↓
Relational Database (PostgreSQL)
```

### 1. Extract

Monthly wholesale reports published by GAIKINDO were collected in PDF format. Since the reports were not compatible, the tables were first converted into CSV files.

### 2. Transform

The raw CSV files contained inconsistent formatting and repeated information. Using Excel Power Query, the data was cleaned, standardized, and normalized into separate datasets representing the fact and dimension tables.

The transformed output consisted of individual CSV files for each table in the database.

### 3. Load

Each CSV file was imported into temporary staging tables in PostgreSQL using the `COPY` command. The cleaned data was then inserted into the corresponding dimension and fact tables while preserving the relationships defined by the Star Schema.

---

## Database Design

### Entity Relationship Diagram (ERD)
The database is organized using a **Star Schema**, with `fact_sales` serving as the central fact table and four supporting dimension tables: `dim_brands`, `dim_cars`, `dim_productions`, and `dim_dates`.

![Entity Relationship Diagram](/assets/er_diagram_white.png)
*Entity Relationship Diagram of the database*

The schema was developed through the normalization process, separating descriptive attributes from transactional sales data to reduce redundancy and maintain organized relationships. While `fact_sales` references the dimension tables through foreign keys, `dim_cars` also depends on `dim_brands`, creating the only parent-child relationship between dimensions.

This structure provides a scalable foundation for analytical queries, allowing sales to be examined across multiple business dimensions such as time, brand, vehicle model, and production type.

---

### Entity Definitions

#### `dim_brands`

Stores information about vehicle manufacturers.

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT | Unique identifier for each brand. |
| `brand_name` | VARCHAR(50) | Manufacturer name (e.g., Toyota, Honda). |
| `brand_hq` | VARCHAR(100) | Country where the manufacturer is headquartered. |
| `quality_index` | NUMERIC(3,2) | Internal quality score represented as a decimal between 0 and 1. |

---

#### `dim_productions`

Stores production information for each vehicle.

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT | Unique identifier for each production record. |
| `production_type` | VARCHAR(20) | Production method (CKD or CBU). |
| `source_country` | VARCHAR(50) | Country where the vehicle was manufactured or imported from. |

---

#### `dim_dates`

Stores the reporting periods used throughout the analysis.

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT | Unique identifier for each reporting period. |
| `month` | VARCHAR(10) | Month abbreviation (e.g., Jan, Feb). |
| `month_number` | INTEGER | Numeric representation of the month (1–12). |
| `year` | INTEGER | Calendar year. |

---

#### `dim_cars`

Stores information about individual vehicle models.

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT | Unique identifier for each vehicle model. |
| `brand_id` | BIGINT | References the manufacturer in `dim_brands`. |
| `model_name` | VARCHAR(100) | Vehicle model name. |
| `transmission_type` | VARCHAR(20) | Transmission type. |
| `fuel_type` | VARCHAR(20) | Fuel or powertrain type. |
| `fuel_category` | VARCHAR(20) | High-level fuel classification (e.g., ICE, xEV). |

---

#### `fact_sales`

Stores the monthly wholesale sales records. Each row represents the sales volume of a specific vehicle model, production type, and reporting period.

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT | Unique identifier for each sales record. |
| `car_id` | BIGINT | References the vehicle model in `dim_cars`. |
| `production_id` | BIGINT | References the production type in `dim_productions`. |
| `date_id` | BIGINT | References the reporting period in `dim_dates`. |
| `sales_units` | INTEGER | Total wholesale units sold. |

---

### Relationship Mapping

The database consists of one central fact table connected to four dimension tables through foreign key relationships. The table below summarizes how each entity is related within the schema.

| Parent Table | Child Table | Relationship | Foreign Key |
|--------------|-------------|--------------|-------------|
| `dim_brands` | `dim_cars` | One-to-Many | `dim_cars.brand_id` → `dim_brands.id` |
| `dim_cars` | `fact_sales` | One-to-Many | `fact_sales.car_id` → `dim_cars.id` |
| `dim_productions` | `fact_sales` | One-to-Many | `fact_sales.production_id` → `dim_productions.id` |
| `dim_dates` | `fact_sales` | One-to-Many | `fact_sales.date_id` → `dim_dates.id` |

---

## Database Setup

The complete database implementation is available in `schema.sql`. Running the script recreates the database from scratch, from the initial schema creation to the final analytical layer.

The script includes:

- Creating the dimension and fact tables
- Creating temporary staging tables
- Importing CSV files using PostgreSQL `COPY`
- Populating the dimension and fact tables from the staging tables
- Handling missing values during data transformation
- Defining primary and foreign key relationships
- Creating indexes to improve query performance
- Creating SQL `VIEW`s for the analytical queries

---

## Optimization

In addition to the database setup, `schema.sql` includes indexes and SQL `VIEW`s that improve performance and simplify the analytical workflow.

### Indexes

Indexes were created on frequently joined and filtered columns to improve query performance, particularly during joins and aggregations.

| Index | Purpose |
|--------|---------|
| `idx_sales_carid` | Speeds up joins between `fact_sales` and `dim_cars`. |
| `idx_sales_productionid` | Speeds up joins between `fact_sales` and `dim_productions`. |
| `idx_sales_dateid` | Speeds up joins between `fact_sales` and `dim_dates`. |
| `idx_cars_brandid` | Improves lookups between `dim_brands` and `dim_cars`. |
| `idx_dates_yearmonth` | Optimizes filtering by year and month. |

### SQL Views

The project defines five SQL `VIEW`s, each encapsulating the business logic for one of the core analytical questions presented in the README.

| View | Purpose |
|------|---------|
| `vw_market_pulse` | Summarizes annual YTD wholesale sales volume. |
| `vw_market_share` | Calculates the top five brands by annual market share. |
| `vw_productions` | Aggregates sales by production type (CKD vs. CBU). |
| `vw_top_models` | Identifies the top three selling models for each of the top five brands. |
| `vw_seasonality` | Ranks the highest-volume sales months for each year. |

By encapsulating the analytical logic into reusable views, the analysis queries remain shorter, easier to maintain, and more readable.

---

## Design Decisions

### Star Schema

A Star Schema was chosen to separate descriptive attributes (dimensions) from transactional data (`fact_sales`). This structure simplifies analytical queries, improves readability, and integrates well with BI tools.

### Surrogate Keys

Each table uses surrogate keys (`id`) rather than business attributes to maintain consistent relationships and avoid issues if descriptive values change over time.

### SQL Views

The five business questions are encapsulated into SQL `VIEW`s to separate business logic from analytical queries, making the SQL easier to reuse and maintain.

### Indexing

Indexes were created on frequently joined and filtered columns to reduce query execution time during aggregations and reporting.

### YTD Comparison

Since 2026 data is currently available only through May, all yearly comparisons are limited to the same January–May period to ensure a fair year-over-year comparison.

---

## Limitations

- **Manual Data Updates:** New GAIKINDO releases must be cleaned and imported manually before they can be analyzed.
- **No Automated ETL Pipeline:** Data preparation relies on Power Query and manual execution of `schema.sql`.
- **Source Dependency:** The database structure depends on the consistency of GAIKINDO's monthly PDF reports.
- **Limited Attributes:** Analysis is restricted to the information available in the source data and does not include pricing, vehicle segments, or retail sales.