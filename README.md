# HighCloud Airlines SQL Analysis

Project Overview
Project Title: HighCloud Airlines Data Analysis
Database: `airlines`

This project demonstrates SQL skills for analyzing airline operations, including data cleaning, transformation, KPI calculations, and insights extraction. The dataset consists of flight records, passenger statistics, and airline performance metrics. The objective is to analyze airline efficiency, optimize operations, and generate insights for better decision-making.

---

## Table of Contents
1. [Dataset Overview](#dataset-overview)
2. [Load Factor Calculation](#load-factor-calculation)
3. [Date Calculations](#date-calculations)
4. [Yearly, Quarterly, Monthly Load Factor %](#yearly-quarterly-monthly-load-factor)
5. [Load Factor by Carrier Name](#load-factor-by-carrier-name)
6. [Top 10 Carriers by Passenger Preference](#top-10-carriers-by-passenger-preference)
7. [Top Routes by Number of Flights](#top-routes-by-number-of-flights)
8. [Load Factor: Weekend vs Weekdays](#load-factor-weekend-vs-weekdays)
9. [Flights Based on Distance Group](#flights-based-on-distance-group)
10. [Flight Search Stored Procedures](#flight-search-stored-procedures)

---

## Dataset Overview
The `maindata` table consists of flight-related information, including:
- Flight schedules (Year, Month, Day, Date)
- Passenger statistics (# Transported Passengers, # Available Seats)
- Flight routes (Origin, Destination, Carrier Name)
- Distance Grouping

---
## Objectives
Database Setup: Create and structure an `airlines` database.
Data Cleaning & Transformation: Handle missing values, format date fields, and compute performance metrics.
Exploratory Data Analysis (EDA): Examine passenger traffic, load factors, and airline efficiency.
Performance Insights: Calculate key performance indicators (KPIs) to assess operational efficiency.

---

## Project Structure
- Database Creation: The project starts with creating a database named highcloud_airlines_db.
- Table Structure: The dataset includes flight information, passenger details, and operational metrics.
  
          

## Queries & Their Purpose

### 1️⃣ Load Factor Calculation
**Purpose:** Calculates the percentage of available seats occupied by passengers.
```sql
ALTER TABLE maindata ADD `Load_Factor` FLOAT;
UPDATE maindata 
SET `Load_Factor` = 
    CASE 
        WHEN `# Available Seats` = 0 OR `# Available Seats` IS NULL THEN 0
        ELSE (`# Transported Passengers` / `# Available Seats`) * 100 
    END;
```

---

### 2️⃣ Date Calculations
**Purpose:** Enhances date-based analysis by adding columns for formatted date, month names, quarters, weekdays, financial months, and financial quarters.
```sql
ALTER TABLE maindata ADD COLUMN `Date` DATE;
UPDATE maindata SET `Date` = DATE(CONCAT(`Year`, "-", `Month (#)`, "-", `Day`));
```

```sql
ALTER TABLE maindata ADD COLUMN `MonthName` VARCHAR(15);
UPDATE maindata SET `MonthName` = MONTHNAME(`Date`);
```

```sql
ALTER TABLE maindata ADD COLUMN `Quarter` VARCHAR(2);
UPDATE maindata SET `Quarter` = CONCAT("Q", QUARTER(`Date`));
```

```sql
ALTER TABLE maindata ADD COLUMN `WeekdayNo` INT;
UPDATE maindata SET `WeekdayNo` = WEEKDAY(`Date`);
```

```sql
ALTER TABLE maindata ADD COLUMN `WeekdayName` VARCHAR(10);
UPDATE maindata SET `WeekdayName` = DAYNAME(`Date`);
```

---

### 3️⃣ Load Factor Analysis
**Purpose:** Calculates yearly, quarterly, and monthly load factor percentages.
```sql
SELECT `Year`, ROUND(SUM(`Load_Factor`) / (SELECT SUM(`Load_Factor`) FROM maindata) * 100, 2) AS `LoadFactor%`
FROM maindata 
GROUP BY `Year`;
```

---

### 4️⃣ Load Factor by Carrier
**Purpose:** Identifies the top 10 carriers with the highest load factor.
```sql
WITH CTE AS (
    SELECT `Unique Carrier`, SUM(`Load_Factor`) AS TotalLoadFactor 
    FROM maindata 
    GROUP BY `Unique Carrier` 
    ORDER BY TotalLoadFactor DESC 
    LIMIT 10
)
SELECT `Unique Carrier`, ROUND(TotalLoadFactor / (SELECT SUM(TotalLoadFactor) FROM CTE) * 100, 2) AS `LoadFactor%`
FROM CTE 
GROUP BY `Unique Carrier` 
ORDER BY TotalLoadFactor DESC;
```

---

### 5️⃣ Top 10 Carriers by Passenger Preference
**Purpose:** Lists the top 10 carriers based on the number of transported passengers.
```sql
SELECT `Unique Carrier`, 
    CASE
        WHEN SUM(`# Transported Passengers`) >= 1000000 
        THEN CONCAT(ROUND(SUM(`# Transported Passengers`) / 1000000, 1), ' M')
        ELSE SUM(`# Transported Passengers`)
    END AS `Transported Passengers`
FROM maindata
GROUP BY `Unique Carrier`
ORDER BY SUM(`# Transported Passengers`) DESC 
LIMIT 10;
```

---

### 6️⃣ Top Routes by Number of Flights
**Purpose:** Finds the busiest flight routes based on the number of flights.
```sql
SELECT `From - To City`, COUNT(`Unique Carrier`) AS TotalFlights 
FROM maindata 
GROUP BY `From - To City` 
ORDER BY TotalFlights DESC 
LIMIT 10;
```

---

### 7️⃣ Load Factor on Weekends vs. Weekdays
**Purpose:** Compares the load factor percentage between weekends and weekdays.
```sql
SELECT `WeekdayType`, ROUND(SUM(`Load_Factor`) / (SELECT SUM(`Load_Factor`) FROM maindata) * 100, 2) AS `LoadFactor%` 
FROM maindata 
GROUP BY `WeekdayType` 
ORDER BY `LoadFactor%`;
```

---

### 8️⃣ Flights Based on Distance Group
**Purpose:** Categorizes flights based on distance groups.
```sql
SELECT `Distance_Interval`, COUNT(`Unique Carrier`) AS TotalFlights 
FROM `distancegroups` D 
INNER JOIN maindata M ON M.`%Distance Group ID` = D.`Distance Group ID`
GROUP BY `Distance_Interval` 
ORDER BY TotalFlights DESC;
```

---

### 9️⃣ Flight Search Stored Procedure
**Purpose:** Searches flights based on origin and destination country.
```sql
delimiter $$
CREATE PROCEDURE `FlightSearchbyCountry`(IN Origin_Country VARCHAR(30), IN Destination_Country VARCHAR(30))
BEGIN
    SELECT `%Airline ID`, `Date`, `Unique Carrier`, `%Region Code`, `%Origin Airport ID`, `%Destination Airport ID`, `Origin Country`, `Origin State`, `Origin City`, `Destination Country`, `Destination State`, `Destination City`
    FROM maindata 
    WHERE (Origin_Country IS NULL OR Origin_Country = `Origin Country`) 
    AND (Destination_Country IS NULL OR Destination_Country = `Destination Country`);
END $$
delimiter ;
```

**Usage:**
```sql
CALL `FlightSearchbyCountry`("United States", "Australia");
CALL `FlightSearchbyCountry`("United States", NULL);
```

---
## Findings
- Seasonality Trends: Passenger traffic varies significantly across months, with peak travel seasons showing increased demand.
- Load Factor Efficiency: Some airlines optimize seating capacity better than others.
- Busiest Routes: Identifying high-demand flight paths helps optimize scheduling and pricing.
- Top Airlines: Certain airlines consistently transport more passengers, indicating strong market presence.

## Reports & Insights
- Passenger Traffic Report: Summarizes monthly and yearly passenger trends.
- Load Factor Analysis: Evaluates airline efficiency in seat occupancy.
- Route Optimization Report: Identifies the busiest and most profitable routes.
- Airline Market Share Report: Highlights the top-performing airlines based on passenger volume.

## Conclusion
This SQL analysis provides a comprehensive overview of airline operations, focusing on flight efficiency, passenger trends, and route analysis. Stored procedures enhance the ability to search flights dynamically based on user input. These queries can be leveraged to optimize airline performance and improve decision-making.

---


