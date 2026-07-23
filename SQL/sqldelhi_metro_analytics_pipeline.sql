-- =============================================================================
-- DELHI METRO OPERATIONS & REVENUE ANALYTICS
-- COMPLETE PRODUCTION SQL PIPELINE (BIGQUERY DATA WAREHOUSE)
-- Author: Aditya Sharma
-- Repository: Delhi-Metro-DMRC-Commuter-Density-Bottleneck-Analytics
-- =============================================================================


-- =============================================================================
-- SECTION 1: DATA CLEANING & STANDARDIZATION (DDL / DML)
-- Description: Clean raw staging table, trim whitespaces, cast data types,
--              impute missing values, and dynamically derive surge categories.
-- =============================================================================

CREATE OR REPLACE TABLE `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips` AS
SELECT DISTINCT
    CAST(TripID AS INT64) AS TripID,
    CAST(Date AS DATE) AS Date,
    
    -- Text Standardization (Trimming Whitespaces)
    TRIM(From_Station) AS From_Station_Clean,
    TRIM(To_Station) AS To_Station_Clean,
    
    -- Datatype Standardization
    CAST(Distance_km AS FLOAT64) AS Distance_Float,
    CAST(Fare AS FLOAT64) AS Fare_Float,
    CAST(Passengers AS INT64) AS Passengers_Clean,
    
    -- Calculated Revenue Metric
    ROUND(CAST(Fare AS FLOAT64) * CAST(Passengers AS INT64), 2) AS Total_Revenue_Calculated,
    
    -- Null Imputation
    COALESCE(TRIM(Ticket_Type), 'Standard') AS Ticket_Type_Clean,
    COALESCE(TRIM(Remarks), 'regular') AS Remarks_Clean,
    
    -- Dynamic Demand Surge Categorization
    CASE 
        WHEN LOWER(Remarks) LIKE '%peak%' OR LOWER(Remarks) LIKE '%surge%' THEN 'High Demand Surge'
        WHEN LOWER(Remarks) LIKE '%festival%' OR LOWER(Remarks) LIKE '%event%' THEN 'Special Event Spike'
        WHEN LOWER(Remarks) LIKE '%maintenance%' THEN 'Operational Maintenance'
        WHEN LOWER(Remarks) LIKE '%weekend%' THEN 'Weekend Moderate'
        ELSE 'Normal Flow'
    END AS Demand_Category

FROM `delhi-metro-project-503214.Delhi_Metro.raw_fact_trips`
WHERE CAST(Fare AS FLOAT64) >= 0 
  AND CAST(Passengers AS INT64) > 0;


-- =============================================================================
-- SECTION 2: ADVANCED BUSINESS ANALYTICS QUERIES
-- Description: Advanced CTEs, Window Functions, Ranking, and Subqueries
--              used for business intelligence extraction.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 2.1: CTE + HAVING Clause (High Congestion Bottleneck Stations)
-- Goal: Isolate primary origin stations handling >5,000 trips.
-- -----------------------------------------------------------------------------
WITH Station_Traffic AS (
    SELECT 
        From_Station_Clean AS Station_Name,
        COUNT(TripID) AS Total_Trips,
        SUM(Passengers_Clean) AS Total_Passengers,
        SUM(Total_Revenue_Calculated) AS Total_Revenue
    FROM `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips`
    GROUP BY From_Station_Clean
    HAVING COUNT(TripID) > 5000
)
SELECT 
    Station_Name,
    Total_Trips,
    Total_Passengers,
    ROUND(Total_Revenue, 2) AS Total_Revenue_INR
FROM Station_Traffic
ORDER BY Total_Passengers DESC;


-- -----------------------------------------------------------------------------
-- Query 2.2: Window Function & Ranking (DENSE_RANK)
-- Goal: Rank Top 3 Origin-Destination routes per Demand Category.
-- -----------------------------------------------------------------------------
WITH Route_Summary AS (
    SELECT 
        Demand_Category,
        CONCAT(From_Station_Clean, ' -> ', To_Station_Clean) AS Route_Name,
        SUM(Passengers_Clean) AS Total_Passengers,
        DENSE_RANK() OVER(
            PARTITION BY Demand_Category 
            ORDER BY SUM(Passengers_Clean) DESC
        ) AS Route_Rank
    FROM `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips`
    GROUP BY Demand_Category, From_Station_Clean, To_Station_Clean
)
SELECT 
    Demand_Category,
    Route_Rank,
    Route_Name,
    Total_Passengers
FROM Route_Summary
WHERE Route_Rank <= 3
ORDER BY Demand_Category, Route_Rank;


-- -----------------------------------------------------------------------------
-- Query 2.3: Subquery Analytics (Ticket Product Revenue Contribution %)
-- Goal: Calculate exact revenue yield contribution percentage per ticket product.
-- -----------------------------------------------------------------------------
SELECT 
    Ticket_Type_Clean AS Ticket_Type,
    COUNT(TripID) AS Total_Bookings,
    SUM(Passengers_Clean) AS Total_Passengers,
    ROUND(SUM(Total_Revenue_Calculated), 2) AS Product_Revenue_INR,
    ROUND(
        (SUM(Total_Revenue_Calculated) / (SELECT SUM(Total_Revenue_Calculated) FROM `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips`)) * 100, 
        2
    ) AS Revenue_Contribution_Pct
FROM `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips`
GROUP BY Ticket_Type_Clean
ORDER BY Product_Revenue_INR DESC;


-- -----------------------------------------------------------------------------
-- Query 2.4: Cumulative Sum & 7-Day Moving Average Window Functions
-- Goal: Measure ridership growth trends and smooth daily variations.
-- -----------------------------------------------------------------------------
WITH Daily_Transit_Stats AS (
    SELECT 
        Date,
        SUM(Passengers_Clean) AS Daily_Passengers,
        ROUND(SUM(Total_Revenue_Calculated), 2) AS Daily_Revenue
    FROM `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips`
    GROUP BY Date
)
SELECT 
    Date,
    Daily_Passengers,
    SUM(Daily_Passengers) OVER(ORDER BY Date ASC) AS Cumulative_Passengers,
    Daily_Revenue,
    ROUND(
        AVG(Daily_Passengers) OVER(
            ORDER BY Date ASC 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 
        2
    ) AS Moving_Avg_7_Days_Passengers
FROM Daily_Transit_Stats
ORDER BY Date ASC;


-- =============================================================================
-- SECTION 3: CONSOLIDATED MASTER TABLE (BI WAREHOUSE SCHEMA)
-- Description: Create a unified summary master table optimized for Looker Studio,
--              Tableau, and Power BI dashboards.
-- =============================================================================

CREATE OR REPLACE TABLE `delhi-metro-project-503214.Delhi_Metro.summary_fact_trips_master` AS
SELECT 
    TripID,
    Date,
    EXTRACT(YEAR FROM Date) AS Year,
    EXTRACT(MONTH FROM Date) AS Month_Number,
    FORMAT_DATE('%B', Date) AS Month_Name,
    FORMAT_DATE('%A', Date) AS Day_Name,
    CASE WHEN EXTRACT(DAYOFWEEK FROM Date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS Day_Type,
    
    From_Station_Clean AS Origin_Station,
    To_Station_Clean AS Destination_Station,
    CONCAT(From_Station_Clean, ' -> ', To_Station_Clean) AS Route_Name,
    
    Distance_Float AS Distance_KM,
    Fare_Float AS Fare_INR,
    Passengers_Clean AS Passenger_Count,
    Total_Revenue_Calculated AS Total_Revenue_INR,
    
    Ticket_Type_Clean AS Ticket_Type,
    Remarks_Clean AS Traffic_Remark,
    Demand_Category
FROM `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips`;


-- =============================================================================
-- SECTION 4: DOMAIN FEATURE ENGINEERING
-- Description: Derive machine learning & business features for downstream
--              predictive modeling and executive decision-making.
-- =============================================================================

CREATE OR REPLACE TABLE `delhi-metro-project-503214.Delhi_Metro.summary_fact_trips_featured` AS
SELECT 
    *,
    
    -- Feature 1: Revenue Efficiency per Kilometer
    ROUND(
        CASE WHEN Distance_KM > 0 THEN Total_Revenue_INR / Distance_KM ELSE 0 END, 
        2
    ) AS Revenue_Per_KM,
    
    -- Feature 2: Commuter Congestion Grouping
    CASE 
        WHEN Passenger_Count >= 30 THEN 'High Congestion Peak'
        WHEN Passenger_Count BETWEEN 15 AND 29 THEN 'Medium Commuter Flow'
        ELSE 'Low Commuter Volume'
    END AS Passenger_Density_Group,
    
    -- Feature 3: Binary Surge Indicator (1 = Surge/Peak, 0 = Off-Peak)
    CASE 
        WHEN Demand_Category IN ('High Demand Surge', 'Special Event Spike') THEN 1 
        ELSE 0 
    END AS Is_Peak_Surge,
    
    -- Feature 4: Fare Price Tier Category
    CASE 
        WHEN Fare_INR <= 50 THEN 'Budget (<50)'
        WHEN Fare_INR BETWEEN 50.01 AND 100 THEN 'Standard (50-100)'
        ELSE 'Premium (>100)'
    END AS Fare_Tier,
    
    -- Feature 5: High Value Revenue Impact Flag
    CASE 
        WHEN Total_Revenue_INR >= 2500 THEN 'High Revenue Trip'
        ELSE 'Standard Revenue Trip'
    END AS Revenue_Impact_Class

FROM `delhi-metro-project-503214.Delhi_Metro.summary_fact_trips_master`;