# CMS-Hospital-Rating-Analysis
# CMS Hospital General Information - Analysis Project  
**README.md**

## Project Overview

This project involves a rigorous data analysis of the Centers for Medicare & Medicaid Services (CMS) Hospital General Information dataset. The primary goal is to assess, compare, and explain the distribution of hospital overall star ratings (1-5 stars) across different operational and ownership characteristics.

The analysis is performed entirely in **MySQL**, using advanced data cleaning (`ALTER TABLE`, `UPDATE` with `CASE` statements) and aggregation techniques to prepare the data for visualization in a tool like **Tableau Public**.

## Data Source

* **Dataset:** CMS Hospital General Information (`Hospital_General_Information.csv`)
* **Data Period:** [Insert Date Range of Dataset if known, e.g., Q1 2024]
* **Tool Used:** MySQL (with commands configured for local data loading)
* - **Source**: [Hospital General Information](https://data.cms.gov/provider-data/dataset/r4zq-f6fp) (CMS Care Compare)
- **File used**: `Hospital_General_Information.csv` (most recent release at time of analysis)
- Contains ~4,800–5,300 U.S. hospitals (acute care, critical access, and children's hospitals)
- Key columns: Facility ID, Facility Name, State, Hospital Type, Hospital Ownership, Emergency Services, Hospital Overall Rating (1–5 stars), various measure counts, etc.

## Project Goals (Key Questions Answered)

The SQL queries in this repository are designed to answer the following strategic questions:

| Category | Question |
| :--- | :--- |
| **Size** | What is the distribution of hospital ratings by high-level ownership type and emergency services availability? |
| **Rank** | Which regions (States) and hospitals have the highest/lowest average ratings? |
| **Explain** | Which factors (Ownership Type, Emergency Services) are most associated with high ratings? |
| **Compare** | How do for-profit vs. non-profit hospitals compare on overall star ratings? |
| **Action** | (Implied via ranking) Which low-rated hospitals or regions should be prioritized for operational changes? |
```markdown

## Tools Used
- MySQL 8.x
- MySQL Workbench
- Git & GitHub for version control

## Project Structure
```
hospital-cms-analysis/
├── data/
│   └── Hospital_General_Information.csv        
├── sql/
│   ├── 01_schema_and_import.sql
│   ├── 02_data_cleaning.sql
│   └── 03_analysis_queries.sql
├── README.md
└── results/                                    
```

## Key Steps Performed

### 1. Data Import & Schema Creation
- Created `CMS_Hospital_General_information` table with appropriate column types
- Loaded CSV using `LOAD DATA LOCAL INFILE`

### 2. Data Cleaning & Standardization
- Converted "Not Available" ratings → `NULL` and changed column type to `DECIMAL(2,1)`
- Removed rows with missing facility names
- Created two new standardized ownership columns:
  - `Ownership Type Detailed` (granular categories)
  - `Ownership Type Standardized` (Government | Voluntary non-profit | Proprietary (for-profit) | Other/Exclude)

### 1. Data Import & Setup

* **Database:** Uses `CMS_Hospital`.
* **Table Creation:** Creates the `CMS_Hospital_General_information` table with appropriate `VARCHAR` and `INT` types to handle mixed data.
* **Local Loading:** Imports the data from the user's specified local path (`LOAD DATA LOCAL INFILE ...`).

### 2. Data Profiling & Cleaning

This stage focuses on making the raw data usable and reliable:

* **Rating Conversion:** Updates the `'Not Available'` string entries in the `Hospital overall rating` column to `NULL`, and then alters the column type to `DECIMAL(2, 1)` for accurate mathematical calculations.
* **Data Removal:** Deletes potential junk/empty rows.
* **Data Standardization (CRITICAL STEP):**
    * Two new permanent columns are added via `ALTER TABLE`: `Ownership Type Detailed` and `Ownership Type Standardized`.
    * `UPDATE` statements with complex `CASE` logic are used to populate these columns with clean, standardized labels (e.g., 'Voluntary non-profit - Private' becomes **'Private NGO'**).

### 3. Data Shaping (Aggregation Preparation)

This stage calculates the aggregate metrics used for ranking and segmentation, applying strict filters to ensure only relevant facilities (`Acute Care`, `Critical Access`, `Childrens` hospitals with a valid rating) are included:

* **State Aggregation:** Calculates the average rating and facility count per state, forming the basis for geographic ranking.
* **Segment Aggregation:** Calculates the average rating by the high-level **`Ownership Type Standardized`** and **`Emergency Services`** to reveal core performance groups.

### 4. Data Analysis

This section contains the final analytical queries used to extract key insights:

| Query Focus | Purpose |
| :--- | :--- |
| **Top 20 Hospitals** | Identifies the highest-performing facilities (5-star) for benchmarking. |
| **State Ranking** | Lists all states by average rating (DESC). |
| **Detailed Ownership Comparison** | Compares all 10+ standardized ownership groups (e.g., 'Private NGO' vs 'Proprietary Hospital'). |
| **Standardized Ownership Comparison** | Compares the three main categories: **Proprietary (for-profit)**, **Voluntary non-profit**, and **Government**. |
| **Emergency Services Test** | Compares the average rating for hospitals with and without emergency services. |

## Key Insights (Expected Outcomes)

Upon execution and visualization of these queries, the analysis is expected to reveal the following types of insights:

* **Performance Disparity:** Voluntary non-profit hospitals are expected to show a significantly higher average star rating compared to Proprietary (for-profit) and Government hospitals.
* **Geographic Clusters:** Certain states (e.g., in the Mountain West or Upper Midwest) are likely to exhibit regional excellence, providing a benchmark for low-performing states.
* **Operational Trade-off:** Hospitals without emergency services may show a slightly higher average rating, likely due to a less complex operational structure and patient population.
## Author
**Michael Essiful**  
Data Analyst | December 2025

Feel free to fork, star ⭐, or open issues if you find anything interesting!

---
*Data is publicly available from CMS and used for educational/non-commercial purposes.*

This is a template for a comprehensive `README.md` file that you can use for your GitHub repository. It clearly outlines the project's purpose, the data used, and the steps taken within the accompanying SQL file.

***

# 🏥 CMS Hospital Rating Analysis (MySQL)
