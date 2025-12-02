-- CMS Hospital General Information - Review Analysis
-- Importing the dataset

USE CMS_Hospital;

CREATE TABLE CMS_Hospital_General_information (
    `Facility ID` VARCHAR(20) PRIMARY KEY, 
    `Facility Name` VARCHAR(255),
    `Address` VARCHAR(255),
    `City/Town` VARCHAR(100),
    `State` VARCHAR(10),
    `ZIP Code` INT,
    `County/Parish` VARCHAR(100),
    `Telephone Number` VARCHAR(20),
    `Hospital Type` VARCHAR(100),
    `Hospital Ownership` VARCHAR(100),
    `Emergency Services` VARCHAR(5),
    `Meets criteria for birthing friendly designation` VARCHAR(5),
    `Hospital overall rating` VARCHAR(20),
    `Hospital overall rating footnote` VARCHAR(50),
    `MORT Group Measure Count` VARCHAR(20),
    `Count of Facility MORT Measures` VARCHAR(20),
    `Count of MORT Measures Better` VARCHAR(20),
    `Count of MORT Measures No Different` VARCHAR(20),
    `Count of MORT Measures Worse` VARCHAR(20),
    `MORT Group Footnote` VARCHAR(50),
    `Safety Group Measure Count` VARCHAR(20),
    `Count of Facility Safety Measures` VARCHAR(20),
    `Count of Safety Measures Better` VARCHAR(20),
    `Count of Safety Measures No Different` VARCHAR(20),
    `Count of Safety Measures Worse` VARCHAR(20),
    `Safety Group Footnote` VARCHAR(50),
    `READM Group Measure Count` VARCHAR(20),
    `Count of Facility READM Measures` VARCHAR(20),
    `Count of READM Measures Better` VARCHAR(20),
    `Count of READM Measures No Different` VARCHAR(20),
    `Count of READM Measures Worse` VARCHAR(20),
    `READM Group Footnote` VARCHAR(50),
    `Pt Exp Group Measure Count` VARCHAR(20),
    `Count of Facility Pt Exp Measures` VARCHAR(20),
    `Pt Exp Group Footnote` VARCHAR(50),
    `TE Group Measure Count` VARCHAR(20),
    `Count of Facility TE Measures` VARCHAR(20),
    `TE Group Footnote` VARCHAR(50)
);

LOAD DATA LOCAL INFILE '/Users/michaelessiful/Desktop/Data Analysis/Hospital Analysis/Hospital_General_Information.csv'
INTO TABLE CMS_Hospital_General_information
FIELDS TERMINATED BY ','
ENCLOSED BY '\"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Total Facility (Hospital) Count
Select count(*)
From CMS_Hospital_General_Information;

-- Previewing facility distrubution by state
SELECT
    State,
    COUNT(`Facility ID`) AS Facility_Count
FROM
    CMS_Hospital_General_information
GROUP BY
    State
ORDER BY
    Facility_Count DESC
LIMIT 10;

DESCRIBE CMS_Hospital_General_information;

-- Data Profiling
-- a. Rating Distrubution
SELECT
    `Hospital overall rating`,
    COUNT(*) AS Facility_Count
FROM
    CMS_Hospital_General_information
GROUP BY
    `Hospital overall rating`
ORDER BY
    -- Order by rating, treating 'Not Available' as lowest or separate.
    CASE
        WHEN `Hospital overall rating` = 'Not Available' THEN 0
        ELSE CAST(`Hospital overall rating` AS DECIMAL)
    END DESC;
    
-- b. Ownership type breakdown
SELECT
    `Hospital Ownership`,
    COUNT(*) AS Facility_Count
FROM
    CMS_Hospital_General_information
GROUP BY
    `Hospital Ownership`
ORDER BY
    Facility_Count DESC;
    
-- c. Emergency services v non-emergency split
SELECT
    `Emergency Services`,
    COUNT(*) AS Facility_Count
FROM
    CMS_Hospital_General_information
GROUP BY
    `Emergency Services`
ORDER BY
    Facility_Count DESC;
    
-- Data Cleaning
-- a. Handling missing Rating, that is, changing all not available entries to null values
UPDATE CMS_Hospital_General_information
SET `Hospital overall rating` = NULL
WHERE `Hospital overall rating` = 'Not Available';

-- Altering the column type to a number (decimal) for calculations
ALTER TABLE CMS_Hospital_General_information
MODIFY COLUMN `Hospital overall rating` DECIMAL(2, 1);

DELETE FROM CMS_Hospital_General_information
WHERE `Facility Name` IS NULL OR TRIM(`Facility Name`) = '';

-- b. Standadize ownership type

ALTER TABLE CMS_Hospital_General_information
ADD COLUMN `Ownership Type Detailed` VARCHAR(100);

-- Add the new column for comparison (For-Profit/Non-Profit/Government)
ALTER TABLE CMS_Hospital_General_information
ADD COLUMN `Ownership Type Standardized` VARCHAR(50);    

-- Ensure Safe Update Mode is disabled for this bulk operation
SET SQL_SAFE_UPDATES = 0;

UPDATE CMS_Hospital_General_information
SET `Ownership Type Detailed` = CASE `Hospital Ownership`
    WHEN 'Voluntary non-profit - Private' THEN 'Private NGO'
    WHEN 'Proprietary' THEN 'Proprietary Hospital'
    WHEN 'Government - Hospital District or Authority' THEN 'District Hospital'
    WHEN 'Government - Local' THEN 'Local Hospital'
    WHEN 'Voluntary non-profit - Other' THEN 'Voluntary NGO'
    WHEN 'Voluntary non-profit - Church' THEN 'Church NGO'
    WHEN 'Government - State' THEN 'Government Hospital'
    WHEN 'Veterans Health Administration' THEN 'Veterans Hospital'
    WHEN 'Physician' THEN 'Physician Hospital'
    WHEN 'Government - Federal' THEN 'Federal Hospital'
    WHEN 'Department of Defense' THEN 'DoD Hospital'
    WHEN 'Tribal' THEN 'Tribal Hospital'
    ELSE 'Unclassified'
END;

UPDATE CMS_Hospital_General_information
SET `Ownership Type Standardized` = CASE
    WHEN `Hospital Ownership` LIKE 'Government%' THEN 'Government'
    WHEN `Hospital Ownership` LIKE 'Voluntary non-profit%' THEN 'Voluntary non-profit'
    WHEN `Hospital Ownership` IN ('Proprietary', 'Physician') THEN 'Proprietary (for-profit)'
    ELSE 'Other/Exclude' -- For VHA, DoD, Tribal
END;

-- Data Shapping
-- a. Ownership + emergency service segment
SELECT
    `Ownership Type Standardized`,
    `Emergency Services`,
    COUNT(`Facility ID`) AS Facility_Count,
    CAST(AVG(`Hospital overall rating`) AS DECIMAL(3, 2)) AS Average_Rating
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL 
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    AND `Ownership Type Standardized` != 'Other/Exclude'
GROUP BY
    `Ownership Type Standardized`,
    `Emergency Services`
ORDER BY
    Average_Rating DESC,
    Facility_Count DESC;
    
-- b. State level aggregation (Average rating by state)
SELECT
    State,
    COUNT(`Facility ID`) AS Facility_Count,
    CAST(AVG(`Hospital overall rating`) AS DECIMAL(3, 2)) AS Average_Rating
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL -- Exclude hospitals with missing ratings
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens') -- Filter relevant types
GROUP BY
    State
HAVING
    COUNT(`Facility ID`) >= 5 -- Only rank states with 5 or more hospitals
ORDER BY
    Average_Rating DESC,
    Facility_Count DESC;

-- c. Average Rating segment

-- d. top 20 hospitals by rating 
SELECT
    `Facility Name`,
    `Hospital overall rating`,
    State,
    `Ownership Type Detailed`, -- Uses your new detailed column
    `Emergency Services`
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL -- Exclude hospitals with missing ratings
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens') -- Filter relevant types
ORDER BY
    `Hospital overall rating` DESC,
    `Facility Name` ASC -- Secondary sort by name for tie-breakers
LIMIT 20;

-- Analysis of Data
-- a. Ranking state by average rating
SELECT
    State,
    COUNT(`Facility ID`) AS Facility_Count,
    CAST(AVG(`Hospital overall rating`) AS DECIMAL(3, 2)) AS Average_Rating
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
GROUP BY
    State
HAVING
    COUNT(`Facility ID`) >= 5 
ORDER BY
    Average_Rating DESC,
    Facility_Count DESC;

-- b. compare rating accross ownership type
SELECT
    `Ownership Type Detailed`,
    COUNT(`Facility ID`) AS Facility_Count,
    CAST(AVG(`Hospital overall rating`) AS DECIMAL(3, 2)) AS Average_Rating
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    AND `Ownership Type Detailed` != 'Unclassified' -- Exclude any rows that didn't match a new label
GROUP BY
    `Ownership Type Detailed`
ORDER BY
    Average_Rating DESC,
    Facility_Count DESC;

-- c. compare rating accross standardized ownership type
SELECT
    `Ownership Type Standardized`,
    COUNT(`Facility ID`) AS Facility_Count,
    CAST(AVG(`Hospital overall rating`) AS DECIMAL(3, 2)) AS Average_Rating
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    AND `Ownership Type Standardized` != 'Other/Exclude'
GROUP BY
    `Ownership Type Standardized`
ORDER BY
    Average_Rating DESC,
    Facility_Count DESC;

-- d. Do emergency hospitals rate higher rate?
SELECT
    `Emergency Services`,
    COUNT(`Facility ID`) AS Facility_Count,
    CAST(AVG(`Hospital overall rating`) AS DECIMAL(3, 2)) AS Average_Rating
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
GROUP BY
    `Emergency Services`
ORDER BY
    Average_Rating DESC;