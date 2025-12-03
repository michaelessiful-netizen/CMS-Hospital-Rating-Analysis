-- Same data set, different Project 
-- Emergency Services Impact Study

-- Data Cleaning 
-- Removing all rows and columns that contains null values
Use CMS_Hospital;
SELECT COUNT(*)
FROM CMS_Hospital_General_information
WHERE `MORT Group Footnote` IS NOT NULL AND TRIM(`MORT Group Footnote`) != '';

DELETE FROM CMS_Hospital_General_information
WHERE
    -- Use the OR condition to check every single column for NULL
    `Facility ID` IS NULL OR `Facility Name` IS NULL OR `Address` IS NULL OR `City/Town` IS NULL OR `State` IS NULL OR
    `ZIP Code` IS NULL OR `County/Parish` IS NULL OR `Telephone Number` IS NULL OR `Hospital Type` IS NULL OR
    `Hospital Ownership` IS NULL OR `Emergency Services` IS NULL OR `Meets criteria for birthing friendly designation` IS NULL OR
    `Hospital overall rating` IS NULL OR `Hospital overall rating footnote` IS NULL OR `MORT Group Measure Count` IS NULL OR
    `Count of Facility MORT Measures` IS NULL OR `Count of MORT Measures Better` IS NULL OR `Count of MORT Measures No Different` IS NULL OR
    `Count of MORT Measures Worse` IS NULL OR `MORT Group Footnote` IS NULL OR `Safety Group Measure Count` IS NULL OR
    `Count of Facility Safety Measures` IS NULL OR `Count of Safety Measures Better` IS NULL OR `Count of Safety Measures No Different` IS NULL OR
    `Count of Safety Measures Worse` IS NULL OR `Safety Group Footnote` IS NULL OR `READM Group Measure Count` IS NULL OR
    `Count of Facility READM Measures` IS NULL OR `Count of READM Measures Better` IS NULL OR `Count of READM Measures No Different` IS NULL OR
    `Count of READM Measures Worse` IS NULL OR `READM Group Footnote` IS NULL OR `Pt Exp Group Measure Count` IS NULL OR
    `Count of Facility Pt Exp Measures` IS NULL OR `Pt Exp Group Footnote` IS NULL OR `TE Group Measure Count` IS NULL OR
    `Count of Facility TE Measures` IS NULL OR `TE Group Footnote` IS NULL;
    
-- change all Not Available entries to 0

-- 1. Update all count/measure columns where 'Not Available' should be 0

UPDATE CMS_Hospital_General_information
SET
    -- Mortality Measures
    `Count of Facility MORT Measures` = REPLACE(`Count of Facility MORT Measures`, 'Not Available', '0'),
    `Count of MORT Measures Better` = REPLACE(`Count of MORT Measures Better`, 'Not Available', '0'),
    `Count of MORT Measures No Different` = REPLACE(`Count of MORT Measures No Different`, 'Not Available', '0'),
    `Count of MORT Measures Worse` = REPLACE(`Count of MORT Measures Worse`, 'Not Available', '0'),

    -- Safety Measures
    `Count of Facility Safety Measures` = REPLACE(`Count of Facility Safety Measures`, 'Not Available', '0'),
    `Count of Safety Measures Better` = REPLACE(`Count of Safety Measures Better`, 'Not Available', '0'),
    `Count of Safety Measures No Different` = REPLACE(`Count of Safety Measures No Different`, 'Not Available', '0'),
    `Count of Safety Measures Worse` = REPLACE(`Count of Safety Measures Worse`, 'Not Available', '0'),

    -- Readmission Measures
    `Count of Facility READM Measures` = REPLACE(`Count of Facility READM Measures`, 'Not Available', '0'),
    `Count of READM Measures Better` = REPLACE(`Count of READM Measures Better`, 'Not Available', '0'),
    `Count of READM Measures No Different` = REPLACE(`Count of READM Measures No Different`, 'Not Available', '0'),
    `Count of READM Measures Worse` = REPLACE(`Count of READM Measures Worse`, 'Not Available', '0'),

    -- Patient Experience Measures
    `Count of Facility Pt Exp Measures` = REPLACE(`Count of Facility Pt Exp Measures`, 'Not Available', '0'),

    -- Timely & Effective Care Measures
    `Count of Facility TE Measures` = REPLACE(`Count of Facility TE Measures`, 'Not Available', '0');
    
ALTER TABLE CMS_Hospital_General_information
    MODIFY COLUMN `Count of Facility MORT Measures` INT,
    MODIFY COLUMN `Count of MORT Measures Better` INT,
    MODIFY COLUMN `Count of MORT Measures No Different` INT,
    MODIFY COLUMN `Count of MORT Measures Worse` INT,
    MODIFY COLUMN `Count of Facility Safety Measures` INT,
    MODIFY COLUMN `Count of Safety Measures Better` INT,
    MODIFY COLUMN `Count of Safety Measures No Different` INT,
    MODIFY COLUMN `Count of Safety Measures Worse` INT,
    MODIFY COLUMN `Count of Facility READM Measures` INT,
    MODIFY COLUMN `Count of READM Measures Better` INT,
    MODIFY COLUMN `Count of READM Measures No Different` INT,
    MODIFY COLUMN `Count of READM Measures Worse` INT,
    MODIFY COLUMN `Count of Facility Pt Exp Measures` INT,
    MODIFY COLUMN `Count of Facility TE Measures` INT;
    
-- Replace all 'Y' entries with 'Yes'
UPDATE CMS_Hospital_General_information
SET `Meets criteria for birthing friendly designation` = 'Yes'
WHERE `Meets criteria for birthing friendly designation` = 'Y'; 

-- Replace all NULL or empty/blank entries with 'No'
UPDATE CMS_Hospital_General_information
SET `Meets criteria for birthing friendly designation` = 'No'
WHERE
    `Meets criteria for birthing friendly designation` IS NULL
    OR TRIM(`Meets criteria for birthing friendly designation`) = '';
    
-- 1. Overall Performance & Rating Impact
-- a. Rating correlation (Average diff between Hospitals with Emergency services and those that do not)
SELECT
    `Emergency Services`,
    CAST(AVG(`Hospital overall rating`) AS DECIMAL(3, 2)) AS Average_Rating
FROM
    CMS_Hospital_General_information
WHERE
    -- Filter to relevant hospital types and those with a valid rating
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
GROUP BY
    `Emergency Services`
ORDER BY
    Average_Rating DESC;
    
SELECT
    -- Calculate the difference: Avg(Yes) - Avg(No)
    CAST(
        (SELECT AVG(`Hospital overall rating`) FROM CMS_Hospital_General_information
         WHERE `Emergency Services` = 'Yes'
         AND `Hospital overall rating` IS NOT NULL
         AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
        )
        -
        (SELECT AVG(`Hospital overall rating`) FROM CMS_Hospital_General_information
         WHERE `Emergency Services` = 'No'
         AND `Hospital overall rating` IS NOT NULL
         AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
        )
    AS DECIMAL(3, 2)) AS Rating_Difference_Emergency_vs_NoEmergency;

-- b. How many of the top 10 hospitals with the Highest rating offer emergency services.
-- Top 10 Hospitals
SELECT
    COUNT(`Facility ID`) AS Hospitals_In_Top10_With_Emergency_Services
FROM
    -- Step 1: Select the 10 highest-rated hospitals
    (
        SELECT
            `Facility ID`,
            `Emergency Services`
        FROM
            CMS_Hospital_General_information
        WHERE
            -- Essential filters for valid ratings and relevant hospital types
            `Hospital overall rating` IS NOT NULL
            AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
        ORDER BY
            `Hospital overall rating` DESC
        LIMIT 10
    ) AS Top10Hospitals
WHERE
    -- Step 2: Count how many of those 10 offer emergency services
    Top10Hospitals.`Emergency Services` = 'Yes';
    
    SELECT
    `Facility Name`,
    `Hospital overall rating`,
    State,
    `Hospital Type`,
    `Ownership Type Detailed`,
    `Emergency Services`
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    AND `Hospital overall rating` IS NOT NULL
ORDER BY
    `Hospital overall rating` DESC,
    `Facility Name` ASC -- Secondary sort by name for tie-breakers
LIMIT 10;

-- 2.Quality and Outcome measure
-- a. Safety Measures: Do hospitals without Emergency Services score significantly better on Safety Group Measures?
SELECT
    `Emergency Services`,
    COUNT(`Facility ID`) AS Facility_Count,
    CAST(AVG(`Count of Safety Measures Better`) AS DECIMAL(5, 2)) AS Avg_Safety_Measures_Better
FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
GROUP BY
    `Emergency Services`
ORDER BY
    Avg_Safety_Measures_Better DESC;

-- b.Patient Experience (Pt Exp): How does the Patient Experience (Pt Exp) Measure Count differ between hospitals with and without Emergency Services? 
SELECT
    `Emergency Services`,
    COUNT(`Facility ID`) AS Facility_Count,
    -- Calculate the average number of Patient Experience Measures reported per hospital
    CAST(AVG(`Count of Facility Pt Exp Measures`) AS DECIMAL(5, 2)) AS Avg_Pt_Exp_Measure_Count
FROM
    CMS_Hospital_General_information
WHERE
    -- Filter to relevant hospital types (Acute Care, Critical Access, Childrens)
    `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
GROUP BY
    `Emergency Services`
ORDER BY
    Avg_Pt_Exp_Measure_Count DESC;

-- c. Mortality/Readmissions:How do READM (Readmission) and MORT(Mortality) measure counts compare between hospitals that offer Emergency Services versus those that do not? 
SELECT
    `Emergency Services`,
    COUNT(`Facility ID`) AS Facility_Count,
    -- Average number of mortality measures reported
    CAST(AVG(`Count of Facility MORT Measures`) AS DECIMAL(5, 2)) AS Avg_MORT_Measure_Count,
    -- Average number of readmission measures reported
    CAST(AVG(`Count of Facility READM Measures`) AS DECIMAL(5, 2)) AS Avg_READM_Measure_Count
FROM
    CMS_Hospital_General_information
WHERE
    -- Filter to relevant hospital types and non-null overall ratings
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
GROUP BY
    `Emergency Services`
ORDER BY
    Avg_READM_Measure_Count DESC;

-- 3. Operational and Geographocal Segmentation
-- a. Ownership strategy: which ownership is least likely to invest in or maintain Emergency Services, and how do their ratings compare to similar hospitals in the same ownership group that do offer ER services?
SELECT
    -- Grouping column
    `Ownership Type Standardized`,

    -- 1. Identifing the 'Least Likely' Investor
    COUNT(`Facility ID`) AS Total_Facilities,
    SUM(CASE WHEN `Emergency Services` = 'No' THEN 1 ELSE 0 END) AS No_Emergency_Count,
    -- Calculating the percentage of hospitals in this group that DO NOT offer ER services
    CAST(SUM(CASE WHEN `Emergency Services` = 'No' THEN 1 ELSE 0 END) * 100.0 / COUNT(`Facility ID`) AS DECIMAL(5, 2)) AS Pct_No_Emergency_Services,

    -- 2. Comparing Ratings for this Ownership Type
    -- Average rating for hospitals that DO offer ER services
    CAST(AVG(CASE WHEN `Emergency Services` = 'Yes' THEN `Hospital overall rating` END) AS DECIMAL(3, 2)) AS Avg_Rating_With_ER,
    -- Average rating for hospitals that DO NOT offer ER services
    CAST(AVG(CASE WHEN `Emergency Services` = 'No' THEN `Hospital overall rating` END) AS DECIMAL(3, 2)) AS Avg_Rating_Without_ER

FROM
    CMS_Hospital_General_information
WHERE
    `Hospital overall rating` IS NOT NULL
    AND `Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    -- Focusing on the main three standardized ownership types
    AND `Ownership Type Standardized` IN ('Proprietary (for-profit)', 'Voluntary non-profit', 'Government')
GROUP BY
    `Ownership Type Standardized`
ORDER BY
    -- Order by the highest percentage of 'No' emergency services to find the 'least likely' investor
    Pct_No_Emergency_Services DESC;

-- b. Operational complexity: How does the distribution of Emergency Services vary across Hospital Type? What percentage of Critical Access Hospitals (CAHs) offer Emergency Services, and how does this affect their star rating?
SELECT
    t.`Hospital Type`,
    COUNT(t.`Facility ID`) AS Total_Facilities,
    -- Counting the facilities that are offering Emergency Services
    SUM(CASE WHEN t.`Emergency Services` = 'Yes' THEN 1 ELSE 0 END) AS Yes_Emergency_Count,
    -- Calculating the percentage of facilities with Emergency Services
    CAST(SUM(CASE WHEN t.`Emergency Services` = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(t.`Facility ID`) AS DECIMAL(5, 2)) AS Pct_With_Emergency_Services,
    -- Calculating the average rating for hospitals that are offering ER
    CAST(AVG(CASE WHEN t.`Emergency Services` = 'Yes' THEN t.`Hospital overall rating` END) AS DECIMAL(3, 2)) AS Avg_Rating_With_ER,
    -- Calculating the average rating for hospitals that are not offering ER
    CAST(AVG(CASE WHEN t.`Emergency Services` = 'No' THEN t.`Hospital overall rating` END) AS DECIMAL(3, 2)) AS Avg_Rating_Without_ER
FROM
    CMS_Hospital_General_information AS t
WHERE
    -- Filtering to the core hospital types relevant to this analysis (Acute Care, Critical Access, Childrens)
    t.`Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    -- Ensuring the overall rating is not null for accurate comparison
    AND t.`Hospital overall rating` IS NOT NULL
GROUP BY
    t.`Hospital Type`
ORDER BY
    -- Ordering the results by the total number of facilities
    Total_Facilities DESC;

-- c. Access Gaps: Which States or Counties have the highest proportion of hospitals without Emergency Services, indicating potential geographic gaps in emergency access for the local population?
 SELECT
    t.State,
    COUNT(t.`Facility ID`) AS Total_Facilities,
    -- Counting facilities that are not offering Emergency Services
    SUM(CASE WHEN t.`Emergency Services` = 'No' THEN 1 ELSE 0 END) AS No_Emergency_Count,
    -- Calculating the percentage of facilities without Emergency Services
    CAST(SUM(CASE WHEN t.`Emergency Services` = 'No' THEN 1 ELSE 0 END) * 100.0 / COUNT(t.`Facility ID`) AS DECIMAL(5, 2)) AS Pct_No_Emergency_Services
FROM
    CMS_Hospital_General_information AS t
WHERE
    -- Filtering to the core hospital types relevant to this analysis
    t.`Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    -- Ensuring the overall rating is not null
    AND t.`Hospital overall rating` IS NOT NULL
GROUP BY
    t.State
HAVING
    -- Only including states that are having enough data points for robust analysis
    COUNT(t.`Facility ID`) >= 5
ORDER BY
    -- Ordering by the percentage without Emergency Services to highlight the highest gaps
    Pct_No_Emergency_Services DESC,
    Total_Facilities DESC;
    
SELECT
    t.`County/Parish`,
    t.State,
    COUNT(t.`Facility ID`) AS Total_Facilities,
    -- Counting facilities that are not offering Emergency Services
    SUM(CASE WHEN t.`Emergency Services` = 'No' THEN 1 ELSE 0 END) AS No_Emergency_Count,
    -- Calculating the percentage of facilities without Emergency Services
    CAST(SUM(CASE WHEN t.`Emergency Services` = 'No' THEN 1 ELSE 0 END) * 100.0 / COUNT(t.`Facility ID`) AS DECIMAL(5, 2)) AS Pct_No_Emergency_Services
FROM
    CMS_Hospital_General_information AS t
WHERE
    -- Filtering to the core hospital types relevant to this analysis
    t.`Hospital Type` IN ('Acute Care Hospitals', 'Critical Access Hospitals', 'Childrens')
    -- Ensuring the overall rating is not null
    AND t.`Hospital overall rating` IS NOT NULL
GROUP BY
    t.`County/Parish`, t.State
HAVING
    -- Only including counties that are having at least 3 facilities for local significance
    COUNT(t.`Facility ID`) >= 3
ORDER BY
    -- Ordering by the percentage without Emergency Services to highlight the highest gaps
    Pct_No_Emergency_Services DESC,
    Total_Facilities DESC;