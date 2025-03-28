/*================================ HighCloud Airlines ===================================================================================================*/

-- Sample Data Preview --
SELECT * FROM maindata LIMIT 10;

SET SQL_SAFE_UPDATES = 0;

-- Load Factor Calculation --
ALTER TABLE maindata ADD `Load_Factor` FLOAT;
UPDATE maindata 
SET `Load_Factor` = 
    CASE 
        WHEN `# Available Seats` = 0 OR `# Available Seats` IS NULL THEN 0
        ELSE (`# Transported Passengers` / `# Available Seats`) * 100 
    END;

-- Working: CASE statement to handel 0 & Null values in the denominator



##----------- KPI 1: Date Calculations --------------------------------------------------------------------------------------------------------------
-- Create Date Column --
ALTER TABLE maindata ADD COLUMN `Date` DATE;
UPDATE maindata 
SET `Date` = DATE(CONCAT(`Year`, "-", `Month (#)`, "-", `Day`));

-- Add Month Name --
ALTER TABLE maindata ADD COLUMN `MonthName` VARCHAR(15);
UPDATE maindata 
SET `MonthName` = MONTHNAME(`Date`);

-- Add Quarter --
ALTER TABLE maindata ADD COLUMN `Quarter` VARCHAR(2);
UPDATE maindata 
SET `Quarter` = CONCAT("Q", QUARTER(`Date`));

-- Add Weekday Number --
ALTER TABLE maindata ADD `WeekdayNo` INT;
UPDATE maindata 
SET `WeekdayNo` = WEEKDAY(`Date`);

-- Add Weekday Name --
ALTER TABLE maindata ADD `WeekdayName` VARCHAR(10);
UPDATE maindata 
SET `WeekdayName` = DAYNAME(`Date`);

-- Add Weekday Type --
ALTER TABLE maindata ADD `WeekdayType` VARCHAR(10);
UPDATE maindata 
SET `WeekdayType` = 
    CASE 
        WHEN `WeekdayNo` IN (5, 6) THEN "Weekend"
        ELSE "Weekday"
    END;

-- Add Year-Month Column --
ALTER TABLE maindata ADD `Year-Month` VARCHAR(20);
UPDATE maindata 
SET `Year-Month` = CONCAT(`Year`, "-", LEFT(`MonthName`, 3));

-- Add Financial Month --
ALTER TABLE maindata ADD `FinancialMonth` VARCHAR(10);
UPDATE maindata 
SET `FinancialMonth` = 
    CASE 
        WHEN `Month (#)` >= 4 THEN concat("FM-",`Month (#)` - 3)
        ELSE concat("FM-",`Month (#)` + 9 )
    END;

-- Add Financial Quarter --
ALTER TABLE maindata ADD COLUMN `FinancialQuarter` VARCHAR(5);
UPDATE maindata 
SET `FinancialQuarter` = 
    CASE `Quarter`
        WHEN "Q2" THEN "FQ-1" 
        WHEN "Q3" THEN "FQ-2"
        WHEN "Q4" THEN "FQ-3"
        ELSE "FQ-4"
    END;


SELECT `Year`, `Month (#)`, `Day`, `Date`, `Year-Month`, `MonthName`, `Quarter`, `WeekdayNo`, `WeekdayName`, `WeekdayType`, `FinancialMonth`, `FinancialQuarter`
FROM maindata;


##-- KPI 2: Yearly, Quarterly, Monthly Load Factor % ------------------------------------------------------------------------------------------------------------------------
-- Yearly Load Factor% --
SELECT `Year`, ROUND(SUM(`Load_Factor`) / (SELECT SUM(`Load_Factor`) FROM maindata) * 100, 2) AS `LoadFactor%`
FROM maindata 
GROUP BY `Year`;

-- Quarterly Load Factor% --
SELECT `Quarter`, ROUND(SUM(`Load_Factor`) / (SELECT SUM(`Load_Factor`) FROM maindata) * 100, 2) AS `LoadFactor%`
FROM maindata 
GROUP BY `Quarter`
ORDER BY `Quarter`;

-- Monthly Load Factor% --
SELECT `MonthName`, ROUND(SUM(`Load_Factor`) / (SELECT SUM(`Load_Factor`) FROM maindata) * 100, 2) AS `LoadFactor%`
FROM maindata 
GROUP BY `MonthName`, `Month (#)`
ORDER BY `Month (#)`;

-- Working: divided sum(Load_Factor) for each year/Quarter/Month by SUBQUERY which calculated overall sum(Load_Factor), And Rounding it to 2 decimals


##------ KPI 3: Load Factor by Carrier Name ---------------------------------------------------------------------------------------------------------------------------------
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


##-------- KPI 4: Top 10 Carriers by Passenger Preference ----------------------------------------------------------------------------------------------------------------------

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



##----- KPI 5: Top Routes by Number of Flights -----------------------------------------------------------------------------------------------------------------------------------

SELECT `From - To City`, COUNT(`Unique Carrier`) AS TotalFlights 
FROM maindata 
GROUP BY `From - To City` 
ORDER BY TotalFlights DESC 
LIMIT 10;



##----- KPI 6: Load Factor Weekend vs Weekdays --------------------------------------------------------------------------------------------------------------------------------------
SELECT `WeekdayType`, ROUND(SUM(`Load_Factor`) / (SELECT SUM(`Load_Factor`) FROM maindata) * 100, 2) AS `LoadFactor%` 
FROM maindata 
GROUP BY `WeekdayType` 
ORDER BY `LoadFactor%`;


##-------- KPI 7: Flights Based on Distance Group ---------------------------------------------------------------------------------------------------------------------------------------

SELECT `Distance_Interval`, COUNT(`Unique Carrier`) AS TotalFlights 
FROM `distancegroups` D 
INNER JOIN maindata M ON M.`%Distance Group ID` = D.`Distance Group ID`
GROUP BY `Distance_Interval` 
ORDER BY TotalFlights DESC;



-- Working: Imported `distance groups` table and perfomed inner join to get Total Number of Flights for each distance interval






##--------------- Flight Search ----------------------------------------------------------------------------------------------

# Stored Procedure to Search Flights 

delimiter $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `FlightSearchbyCountry`(IN Origin_Country varchar(30),IN Destination_Country varchar(30))
BEGIN
select `%Airline ID`,`Date`, `Unique Carrier`,`%Region Code`,`%Origin Airport ID`,`%Destination Airport ID`,`Origin Country`,`Origin State`,`Origin City`,`Destination Country`,`Destination State`,`Destination City` 
from maindata 
where (Origin_Country is Null or  Origin_Country = `Origin Country`) 
and (Destination_Country is Null or Destination_Country = `Destination Country`);
END $$
Delimiter ;




-- Working:Created 3 stored procedures with input parameters to query results by Origin Country/State/City 
--         and Destination Country/State/City. Included NULL handeling to search based on either Origi, Destination or by both

# Search Flights by Country( Origin Country, Destination Country)
CALL `FlightSearchbyCountry` ("United States", "Australia");
CALL `FlightSearchbyCountry` ("United States", Null);

# Search Flights by State( Origin State, Destination State)
CALL `FlightSearchbyState`("Alaska", "Washington");

# Search Flights by City( Origin City, Destination City)
CALL `FlightSearchbyCity` ("Red Dog, AK", "Kotzebue, AK");



