# 🚆 Delhi-Metro-DMRC-Commuter-Density-Bottleneck-Analytics

[![Google Data Analytics](https://img.shields.io/badge/Google%20Data%20Analytics-Project-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://coursera.org)
[![BigQuery](https://img.shields.io/badge/Google_BigQuery-Data_Warehouse-669DF6?style=for-the-badge&logo=googlecloud&logoColor=white)](https://cloud.google.com/bigquery)
[![Looker Studio](https://img.shields.io/badge/Looker_Studio-Interactive_Dashboard-4285F4?style=for-the-badge&logo=googledatastudio&logoColor=white)](https://lookerstudio.google.com)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)

An end-to-end enterprise data analytics & engineering project evaluating **150,000 transit trip records** across the Delhi Metro (DMRC) network. Built following the **Google 6-Step Data Analysis Framework** (*Ask, Prepare, Process, Analyze, Share, Act*), this repository features BigQuery SQL pipelines, SciPy statistical hypothesis testing, interactive Looker Studio dashboarding, and strategic business recommendations.

---

## 📌 Executive Summary & Key Highlights

* **Total Revenue Analyzed:** **₹31.53 Crore** ($₹315,386,664.91$) across 150,000 valid transacted trips.
* **Ridership Volume:** **3.0 Million+ Passengers** handled across the network.
* **Primary Bottleneck:** **Rajiv Chowk (349,784 passengers)** and **Noida City Centre (278,174 passengers)** generate **2.5x higher traffic** than mid-tier major hubs.
* **Monetization Winner:** **Tourist Cards drive 39.5% (~₹12.45 Cr)** of total revenue despite lower volume, outperforming Single Tokens (25.0%) and Smart Cards (24.8%).
* **Statistical Finding (T-Test):** Proven static pricing structure ($p = 0.517$) with zero fare variance between peak surge and off-peak hours, unlocking a massive **Time-of-Day Dynamic Pricing Opportunity**.

---

## 👨‍💻 Project Metadata & Author

* **Author:** Aditya Sharma
* **Education:** B.Sc. (Hons) Physics, Hansraj College, University of Delhi
* **Scholarship:** Dell Aspire Scholar
* **Target Roles:** Data Analyst | Data Engineer | Google Data Analytics Apprentice
* **Project Name:** `Delhi-Metro-DMRC-Commuter-Density-Bottleneck-Analytics`
* **Tech Stack:** Google BigQuery (SQL), Python (Pandas, NumPy, SciPy, Matplotlib, Seaborn), SQLite3, Google Looker Studio, GitHub

---

## 📊 Interactive Looker Studio Executive Dashboard

<p align="center">
  <img src="Screenshot of Dashboard.png" alt="Delhi Metro Looker Studio Dashboard" width="95%"/>
</p>

live dashboard

https://datastudio.google.com/reporting/18a68b3e-2405-4c9b-9ec3-826d19317ca8

---

## 🎯 Business Problem & Core Objectives

1. **Capacity & Flow Bottlenecks:** Severe interchange overcrowding at core hubs increases platform dwell times and safety risks.
2. **Product Monetization Inefficiency:** Unclear contribution yields across multi-tier ticketing products (Tokens vs. Smart Cards vs. Tourist Passes).
3. **Static Tariff Structure:** Lack of time-of-day pricing mechanisms leads to unmitigated rush-hour demand spikes.
4. **Maintenance Scheduling:** Uncoordinated track/fleet overhauls scheduled during peak festive months cause unnecessary service disruptions.

---

## 📁 Repository Structure & Deliverables

├── SQL/
│   └── sqldelhi_metro_analytics_pipeline.sql  # Complete BigQuery SQL Data Cleaning & Feature Engineering Pipeline
├── DOCUMENT/
│   ├── delhi-metro-report.pdf                 # Full Capstone Project Report (PDF)
│   └── Delhi-Metro-Presentation.pdf           # 8-Slide Executive Pitch Deck (PDF)
├── visualizations/
│   ├── metro 1 visualization.png             # Top 10 High-Volume Origin Stations
│   ├── metro 2 visualization.png             # Revenue Share by Ticket Type Donut Chart
│   ├── metro 3 visualization.jpg             # Monthly Ridership Trend Line Plot (2022-2024)
│   └── metro 4 visualization.png             # Multi-Feature Correlation Matrix Heatmap
├── Screenshot of Dashboard.png                # Looker Studio Interactive Dashboard Screenshot
└── README.md                                  # Repository Documentation Page


## ⚙️ Data Engineering & Feature Pipeline

Data staging was executed in SQLite before loading into Google BigQuery (`delhi-metro-project-503214.Delhi_Metro`).

### 🛠️ Engineered Features (5 Business Metrics)
1. **`Revenue_Per_KM`**: Operational yield efficiency per trip distance ($\text{Revenue} / \text{Distance}$).
2. **`Passenger_Density_Group`**: Traffic density classification (`High Congestion Peak` $\ge 30$, `Medium`, `Low Volume`).
3. **`Is_Peak_Surge`**: Binary ML-ready flag (`1` for Surge/Events, `0` for Off-Peak).
4. **`Fare_Tier`**: Categorized fare slabs (`Budget <₹50`, `Standard ₹50-100`, `Premium >₹100`).
5. **`Revenue_Impact_Class`**: High-value trip identifier ($\ge ₹2500$).

sql
-- Sample BigQuery Data Cleaning & Standardization Query
CREATE OR REPLACE TABLE `delhi-metro-project-503214.Delhi_Metro.clean_fact_trips` AS
SELECT DISTINCT
    CAST(TripID AS INT64) AS TripID,
    CAST(Date AS DATE) AS Date,
    TRIM(From_Station) AS From_Station_Clean,
    TRIM(To_Station) AS To_Station_Clean,
    CAST(Distance_km AS FLOAT64) AS Distance_Float,
    CAST(Fare AS FLOAT64) AS Fare_Float,
    CAST(Passengers AS INT64) AS Passengers_Clean,
    ROUND(CAST(Fare AS FLOAT64) * CAST(Passengers AS INT64), 2) AS Total_Revenue_Calculated,
    COALESCE(TRIM(Ticket_Type), 'Standard') AS Ticket_Type_Clean,
    CASE 
        WHEN LOWER(Remarks) LIKE '%peak%' THEN 'High Demand Surge'
        WHEN LOWER(Remarks) LIKE '%festival%' THEN 'Special Event Spike'
        ELSE 'Normal Flow'
    END AS Demand_Category
FROM `delhi-metro-project-503214.Delhi_Metro.raw_fact_trips`
WHERE CAST(Fare AS FLOAT64) >= 0 AND CAST(Passengers AS INT64) > 0;


🧪 Statistical Hypothesis Testing Matrix
<img width="534" height="332" alt="Screenshot 2026-07-23 162351" src="https://github.com/user-attachments/assets/644ee6c8-2cc8-4fec-bb09-7ef6c8466283" />

📈 Visual Analytics Showcase
1. Top 10 High-Congestion Origin HubsInsight: Rajiv Chowk (349,784 passengers) and Noida City Centre (278,174 passengers) represent the heaviest bottleneck hubs in the network. 
2. Revenue Contribution Share by Ticket ProductInsight: Tourist Cards generate 39.5% (~₹12.45 Cr) of total revenue[cite: 1, 2]. Single Journey Tokens (25.0%) and Smart Cards (24.8%) share the remaining major volume[cite: 1, 2].
3. Monthly Ridership Trend & February SeasonalityInsight: Multi-year trend analysis reveals a recurring 12–14% ridership drop every February (~74,000–77,000 trips) compared to mid-year peaks (~87,000 trips)[cite: 1, 2].
4. Feature Correlation MatrixInsight: Distance vs Revenue Per KM exhibits a negative correlation ($-0.47$), showing short-distance dense trips deliver higher operational margins per kilometer.

🎯 Strategic Action Roadmap

Short-Term (0–3 Months): Install automated crowd control gates at Rajiv Chowk & Noida City Centre; Offer 10% instant discount on mobile QR tickets to shift 25% token buyers to digital passes[cite: 1, 2].

Mid-Term (3–6 Months): Implement Time-of-Day Dynamic Pricing with a 15% mid-day discount (11 AM – 4 PM) to flatten rush hour peaks[cite: 1, 2]; Schedule annual heavy maintenance exclusively in February[cite: 1, 2].

Long-Term (6–12 Months): Reduce train arrival headways from 2.5 minutes to 90 seconds on critical bottleneck corridors (Rajiv Chowk -> AIIMS)[cite: 1, 2]; Expand electric feeder bus networks[cite: 1, 2].
